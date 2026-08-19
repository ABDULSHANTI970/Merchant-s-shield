import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/product.dart';

/// Same reasoning as [MarketRepository]/[AuthRepository] — screens talk to
/// this interface, not `cloud_firestore` directly.
abstract class ChatRepository {
  /// All conversations [uid] is part of (as buyer or seller), newest first.
  Stream<List<Conversation>> watchConversations(String uid);

  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Finds an existing conversation for (product, buyer) if one exists,
  /// otherwise creates it. Returns the conversation id either way — this
  /// is what "اطلب عرض سعر" calls, so tapping it twice on the same
  /// product doesn't spawn duplicate threads.
  Future<String> startConversation({required Product product, required AppUser buyer});

  /// [text] can be empty when [imageUrl] is set (photo-only message) —
  /// feature #13, "إرسال صور وملفات". At least one of the two must be
  /// non-empty; implementations should no-op on a fully empty message.
  Future<void> sendMessage({
    required String conversationId,
    required AppUser sender,
    required String text,
    String imageUrl = '',
  });

  /// Marks everything in [conversationId] as read for [uid]. Call this
  /// when a chat screen opens — see the read-state note in ChatMessage.
  Future<void> markAsRead({required String conversationId, required String uid});
}
