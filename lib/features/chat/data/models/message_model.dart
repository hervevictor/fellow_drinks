class MessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id:          map['id'] as String,
        senderId:    map['sender_id'] as String,
        recipientId: map['recipient_id'] as String,
        content:     map['content'] as String,
        isRead:      map['is_read'] as bool? ?? false,
        createdAt:   DateTime.parse(map['created_at'] as String),
      );
}

class ConversationItem {
  final String clientId;
  final String clientName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ConversationItem({
    required this.clientId,
    required this.clientName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  ConversationItem copyWith({int? unreadCount}) => ConversationItem(
        clientId:      clientId,
        clientName:    clientName,
        lastMessage:   lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount:   unreadCount ?? this.unreadCount,
      );
}
