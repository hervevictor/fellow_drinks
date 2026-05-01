import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers/chat_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT PAGE — bascule admin / client
// ═══════════════════════════════════════════════════════════════════════════════

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return profile.isAdmin ? const _AdminChatView() : const _ClientChatView();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLIENT — conversation avec l'admin
// ═══════════════════════════════════════════════════════════════════════════════

class _ClientChatView extends ConsumerWidget {
  const _ClientChatView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminIdProvider);
    return adminAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (adminId) {
        if (adminId == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Support non disponible pour le moment.',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return _ConversationView(
          otherUserId:    adminId,
          otherUserName:  'Fellow Drink Support',
          showBackButton: false,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN — liste des conversations
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminChatView extends ConsumerStatefulWidget {
  const _AdminChatView();

  @override
  ConsumerState<_AdminChatView> createState() => _AdminChatViewState();
}

class _AdminChatViewState extends ConsumerState<_AdminChatView> {
  String? _clientId;
  String? _clientName;

  @override
  Widget build(BuildContext context) {
    if (_clientId != null) {
      return _ConversationView(
        otherUserId:    _clientId!,
        otherUserName:  _clientName ?? 'Client',
        showBackButton: true,
        onBack: () => setState(() {
          _clientId   = null;
          _clientName = null;
        }),
      );
    }
    return _AdminConversationList(
      onOpen: (id, name) => setState(() {
        _clientId   = id;
        _clientName = name;
      }),
    );
  }
}

class _AdminConversationList extends ConsumerWidget {
  final void Function(String id, String name) onOpen;
  const _AdminConversationList({required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(adminConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages clients'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 52, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Aucune conversation pour le moment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, color: AppColors.divider),
            itemBuilder: (_, i) {
              final conv    = conversations[i];
              final hasNew  = conv.unreadCount > 0;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () => onOpen(conv.clientId, conv.clientName),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    conv.clientName.isNotEmpty
                        ? conv.clientName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  conv.clientName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: hasNew ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: hasNew
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        hasNew ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                trailing: hasNew
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : Text(
                        DateFormat('HH:mm')
                            .format(conv.lastMessageAt.toLocal()),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION VIEW — partagée admin et client
// ═══════════════════════════════════════════════════════════════════════════════

class _ConversationView extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool showBackButton;
  final VoidCallback? onBack;

  const _ConversationView({
    required this.otherUserId,
    required this.otherUserName,
    required this.showBackButton,
    this.onBack,
  });

  @override
  ConsumerState<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<_ConversationView> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending     = false;

  @override
  void initState() {
    super.initState();
    ChatRepository().markAsRead(widget.otherUserId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        // Avec reverse:true, position 0 = bas de l'écran (messages récents)
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ChatRepository().sendMessage(
        recipientId: widget.otherUserId,
        content:     text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final messagesAsync =
        ref.watch(conversationProvider(widget.otherUserId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'Commencez la conversation !',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Marquer comme lu (hors du build)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ChatRepository().markAsRead(widget.otherUserId);
                });

                // reverse:true → index 0 (le plus récent) s'affiche en bas.
                // Le séparateur de date doit apparaître au-dessus du PREMIER
                // message de chaque jour (= dernier index du groupe en ordre décroissant).
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg    = messages[i];
                    final isMine = msg.senderId == currentUserId;
                    // Affiche le séparateur quand le message SUIVANT (plus ancien)
                    // est d'un jour différent, ou quand c'est le dernier item (le plus ancien).
                    final showDate = i == messages.length - 1 ||
                        messages[i].createdAt.day !=
                            messages[i + 1].createdAt.day;
                    return Column(
                      children: [
                        if (showDate)
                          _DateSeparator(date: msg.createdAt),
                        _MessageBubble(message: msg, isMine: isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          left:   isMine ? 52 : 0,
          right:  isMine ? 0 : 52,
          bottom: 6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: isMine ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead
                        ? Colors.white
                        : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    final String label;
    if (msgDay == today) {
      label = "Aujourd'hui";
    } else if (msgDay == today.subtract(const Duration(days: 1))) {
      label = 'Hier';
    } else {
      label = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}
