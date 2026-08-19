import 'dart:async';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/product.dart';
import 'chat_repository.dart';

/// Demo-mode chat, following the same pattern as [SampleMarketRepository]:
/// works entirely in memory so the chat UI is fully clickable before
/// Firebase is wired up, but nothing here persists between app restarts.
class SampleChatRepository implements ChatRepository {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final _conversationsController = StreamController<void>.broadcast();
  final Map<String, StreamController<void>> _messageControllers = {};
  int _idCounter = 0;

  @override
  Stream<List<Conversation>> watchConversations(String uid) async* {
    List<Conversation> current() => _conversations.values
        .where((c) => c.buyerId == uid || c.sellerId == uid)
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    yield current();
    yield* _conversationsController.stream.map((_) => current());
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) async* {
    final controller = _messageControllers.putIfAbsent(
      conversationId,
      () => StreamController<void>.broadcast(),
    );
    yield List.from(_messages[conversationId] ?? const []);
    yield* controller.stream.map((_) => List.from(_messages[conversationId] ?? const []));
  }

  @override
  Future<String> startConversation({required Product product, required AppUser buyer}) async {
    final existing = _conversations.values.where(
      (c) => c.productId == product.id && c.buyerId == buyer.uid,
    );
    if (existing.isNotEmpty) return existing.first.id;

    final id = 'demo-convo-${_idCounter++}';
    final openingText = 'مرحبًا، أنا مهتم بـ "${product.name}" — ممكن عرض سعر؟';
    _conversations[id] = Conversation(
      id: id,
      productId: product.id,
      productName: product.name,
      buyerId: buyer.uid,
      buyerName: buyer.label,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      lastMessage: openingText,
      lastMessageSenderId: buyer.uid,
      lastMessageAt: DateTime.now(),
    );
    _messages[id] = [
      ChatMessage(
        id: 'm0',
        senderId: buyer.uid,
        senderName: buyer.label,
        text: openingText,
        createdAt: DateTime.now(),
      ),
    ];
    _conversationsController.add(null);
    return id;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required AppUser sender,
    required String text,
    String imageUrl = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.isEmpty) return;
    final existing = _conversations[conversationId];
    if (existing == null) return;

    final msg = ChatMessage(
      id: 'm${_messages[conversationId]?.length ?? 0}',
      senderId: sender.uid,
      senderName: sender.label,
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(msg);
    _conversations[conversationId] = Conversation(
      id: existing.id,
      productId: existing.productId,
      productName: existing.productName,
      buyerId: existing.buyerId,
      buyerName: existing.buyerName,
      sellerId: existing.sellerId,
      sellerName: existing.sellerName,
      lastMessage: trimmed.isNotEmpty ? trimmed : '📷 صورة',
      lastMessageSenderId: sender.uid,
      lastMessageAt: DateTime.now(),
      buyerLastReadAt: existing.buyerLastReadAt,
      sellerLastReadAt: existing.sellerLastReadAt,
    );
    _messageControllers[conversationId]?.add(null);
    _conversationsController.add(null);
  }

  @override
  Future<void> markAsRead({required String conversationId, required String uid}) async {
    final existing = _conversations[conversationId];
    if (existing == null) return;
    final isBuyer = existing.buyerId == uid;
    final isSeller = existing.sellerId == uid;
    if (!isBuyer && !isSeller) return;

    _conversations[conversationId] = Conversation(
      id: existing.id,
      productId: existing.productId,
      productName: existing.productName,
      buyerId: existing.buyerId,
      buyerName: existing.buyerName,
      sellerId: existing.sellerId,
      sellerName: existing.sellerName,
      lastMessage: existing.lastMessage,
      lastMessageSenderId: existing.lastMessageSenderId,
      lastMessageAt: existing.lastMessageAt,
      buyerLastReadAt: isBuyer ? DateTime.now() : existing.buyerLastReadAt,
      sellerLastReadAt: isSeller ? DateTime.now() : existing.sellerLastReadAt,
    );
    _conversationsController.add(null);
  }
}
