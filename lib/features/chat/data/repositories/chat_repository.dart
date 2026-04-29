import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<String?> getAdminId() async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .limit(1)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Stream<List<MessageModel>> conversationStream(String otherUserId) {
    final uid = _uid;
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data
            .map((e) => MessageModel.fromMap(e))
            .where((m) =>
                (m.senderId == uid && m.recipientId == otherUserId) ||
                (m.senderId == otherUserId && m.recipientId == uid))
            .toList());
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
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['recipient_id'] == uid && e['is_read'] == false)
            .length);
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
