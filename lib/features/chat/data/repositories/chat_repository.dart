import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/message_model.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<String?> getAdminId() async {
    // Cherche d'abord parmi les emails admin définis dans les constantes
    // (plus fiable que se fier uniquement au champ role en DB)
    for (final email in AppConstants.adminEmails) {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (data != null) return data['id'] as String?;
    }
    // Fallback : cherche n'importe quel profil avec role='admin'
    final fallback = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .limit(1)
        .maybeSingle();
    return fallback?['id'] as String?;
  }

  Stream<List<MessageModel>> conversationStream(String otherUserId) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    bool cancelled = false;
    RealtimeChannel? channel;
    late StreamController<List<MessageModel>> controller;

    Future<void> fetchAndEmit() async {
      if (cancelled) return;
      try {
        final List<dynamic> sent = await _client
            .from('messages')
            .select()
            .eq('sender_id', uid)
            .eq('recipient_id', otherUserId)
            .order('created_at', ascending: false);
        final List<dynamic> received = await _client
            .from('messages')
            .select()
            .eq('sender_id', otherUserId)
            .eq('recipient_id', uid)
            .order('created_at', ascending: false);
        if (cancelled) return;
        final msgs = [
          ...sent.map((e) => MessageModel.fromMap(e as Map<String, dynamic>)),
          ...received.map((e) => MessageModel.fromMap(e as Map<String, dynamic>)),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(msgs);
      } catch (e) {
        if (!cancelled) controller.addError(e);
      }
    }

    controller = StreamController<List<MessageModel>>(
      onCancel: () {
        cancelled = true;
        final ch = channel;
        if (ch != null) _client.removeChannel(ch);
      },
    );

    fetchAndEmit();

    channel = _client
        .channel('conv_${uid}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => fetchAndEmit(),
        )
        .subscribe();

    return controller.stream;
  }

  Future<void> sendMessage({
    required String recipientId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'sender_id':   _uid,
      'recipient_id': recipientId,
      'content':     content,
    });
  }

  Future<void> markAsRead(String senderId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', senderId)
        .eq('recipient_id', uid)
        .eq('is_read', false);
  }

  Stream<int> unreadCountStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);

    bool cancelled = false;
    RealtimeChannel? channel;
    late StreamController<int> controller;

    Future<void> fetchAndEmit() async {
      if (cancelled) return;
      try {
        final List<dynamic> data = await _client
            .from('messages')
            .select('id')
            .eq('recipient_id', uid)
            .eq('is_read', false);
        if (cancelled) return;
        controller.add(data.length);
      } catch (_) {
        if (!cancelled) controller.add(0);
      }
    }

    controller = StreamController<int>(
      onCancel: () {
        cancelled = true;
        final ch = channel;
        if (ch != null) _client.removeChannel(ch);
      },
    );

    fetchAndEmit();

    channel = _client
        .channel('unread_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => fetchAndEmit(),
        )
        .subscribe();

    return controller.stream;
  }

  Stream<List<ConversationItem>> adminConversationsStream() {
    final adminId = _uid ?? '';
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final clientIds = <String>{};
          for (final row in data) {
            final s = row['sender_id'] as String;
            final r = row['recipient_id'] as String;
            if (s != adminId) clientIds.add(s);
            if (r != adminId) clientIds.add(r);
          }

          final profileMap = <String, String>{};
          if (clientIds.isNotEmpty) {
            final profiles = await _client
                .from('profiles')
                .select('id, name')
                .inFilter('id', clientIds.toList());
            for (final p in profiles as List) {
              profileMap[p['id'] as String] =
                  p['name'] as String? ?? 'Client';
            }
          }

          final convMap = <String, ConversationItem>{};
          for (final row in data) {
            final s        = row['sender_id'] as String;
            final r        = row['recipient_id'] as String;
            final clientId = s == adminId ? r : s;
            final isUnread = !(row['is_read'] as bool? ?? true) && r == adminId;

            if (!convMap.containsKey(clientId)) {
              convMap[clientId] = ConversationItem(
                clientId:      clientId,
                clientName:    profileMap[clientId] ?? 'Client',
                lastMessage:   row['content'] as String,
                lastMessageAt: DateTime.parse(row['created_at'] as String),
                unreadCount:   isUnread ? 1 : 0,
              );
            } else if (isUnread) {
              final ex = convMap[clientId]!;
              convMap[clientId] = ex.copyWith(unreadCount: ex.unreadCount + 1);
            }
          }

          return convMap.values.toList()
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        });
  }
}
