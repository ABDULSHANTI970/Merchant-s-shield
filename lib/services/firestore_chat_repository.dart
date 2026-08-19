import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/product.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations => _db.collection('conversations');

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    // Firestore can't OR two different fields (buyerId == uid OR
    // sellerId == uid) in one query, so we run both and merge client-side.
    // Fine at this scale — a trader with thousands of simultaneous open
    // conversations isn't the Phase-3 use case this needs to handle.
    final buyerStream = _conversations
        .where('buyerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
    final sellerStream = _conversations
        .where('sellerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    // Combine both streams into one merged, de-duplicated, sorted list
    // every time either side emits.
    late final StreamController<List<Conversation>> controller;
    List<Conversation> buyerList = [];
    List<Conversation> sellerList = [];
    var buyerReady = false;
    var sellerReady = false;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? buyerSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sellerSub;

    void emit() {
      if (!buyerReady || !sellerReady) return;
      final merged = <String, Conversation>{};
      for (final c in buyerList) {
        merged[c.id] = c;
      }
      for (final c in sellerList) {
        merged[c.id] = c;
      }
      final list = merged.values.toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      controller.add(list);
    }

    controller = StreamController<List<Conversation>>.broadcast(
      onListen: () {
        buyerSub = buyerStream.listen((snap) {
          buyerList = snap.docs.map(Conversation.fromFirestore).toList();
          buyerReady = true;
          emit();
        }, onError: controller.addError);
        sellerSub = sellerStream.listen((snap) {
          sellerList = snap.docs.map(Conversation.fromFirestore).toList();
          sellerReady = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await buyerSub?.cancel();
        await sellerSub?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  @override
  Future<String> startConversation({required Product product, required AppUser buyer}) async {
    final existing = await _conversations
        .where('productId', isEqualTo: product.id)
        .where('buyerId', isEqualTo: buyer.uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final conversation = Conversation(
      id: '',
      productId: product.id,
      productName: product.name,
      buyerId: buyer.uid,
      buyerName: buyer.label,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      lastMessage: 'مرحبًا، أنا مهتم بـ "${product.name}" — ممكن عرض سعر؟',
      lastMessageSenderId: buyer.uid,
      lastMessageAt: DateTime.now(),
    );

    final doc = await _conversations.add(conversation.toMap());
    await doc.collection('messages').add(
          ChatMessage(
            id: '',
            senderId: buyer.uid,
            senderName: buyer.label,
            text: conversation.lastMessage,
            createdAt: DateTime.now(),
          ).toMap(),
        );
    return doc.id;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required AppUser sender,
    required String text,
    String imageUrl = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.isEmpty) return; // nothing to send

    final conversationRef = _conversations.doc(conversationId);
    final message = ChatMessage(
      id: '',
      senderId: sender.uid,
      senderName: sender.label,
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await conversationRef.collection('messages').add(message.toMap());
    await conversationRef.update({
      // Conversations-list preview: show something meaningful even for a
      // photo-only message instead of a blank last-message line.
      'lastMessage': trimmed.isNotEmpty ? trimmed : '📷 صورة',
      'lastMessageSenderId': sender.uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAsRead({required String conversationId, required String uid}) async {
    final conversationRef = _conversations.doc(conversationId);
    final snap = await conversationRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final isBuyer = data['buyerId'] == uid;
    final isSeller = data['sellerId'] == uid;
    if (!isBuyer && !isSeller) return; // not a participant — nothing to mark

    await conversationRef.update({
      if (isBuyer) 'buyerLastReadAt': FieldValue.serverTimestamp(),
      if (isSeller) 'sellerLastReadAt': FieldValue.serverTimestamp(),
    });
  }
}
