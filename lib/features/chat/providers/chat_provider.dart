import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

final adminIdProvider = FutureProvider<String?>((ref) {
  return ref.read(chatRepositoryProvider).getAdminId();
});

final conversationProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, otherUserId) {
  return ref.read(chatRepositoryProvider).conversationStream(otherUserId);
});

final unreadCountProvider = StreamProvider<int>((ref) {
  return ref.read(chatRepositoryProvider).unreadCountStream();
});

final adminConversationsProvider =
    StreamProvider<List<ConversationItem>>((ref) {
  return ref.read(chatRepositoryProvider).adminConversationsStream();
});
