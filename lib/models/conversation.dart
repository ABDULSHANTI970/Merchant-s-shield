import 'package:cloud_firestore/cloud_firestore.dart';

/// One chat thread, always tied to a specific product + buyer + seller
/// pair (feature #12: "شات مباشر بين التاجر والمشتري داخل كل صفقة" —
/// scoped per deal, not one giant inbox thread per person).
///
/// Denormalizes product/participant names so the conversations list can
/// render without an extra read per row per product/user lookup.
class Conversation {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageAt;
  final DateTime? buyerLastReadAt;
  final DateTime? sellerLastReadAt;

  const Conversation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    this.buyerLastReadAt,
    this.sellerLastReadAt,
  });

  factory Conversation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Conversation(
      id: doc.id,
      productId: (data['productId'] as String?) ?? '',
      productName: (data['productName'] as String?) ?? '',
      buyerId: (data['buyerId'] as String?) ?? '',
      buyerName: (data['buyerName'] as String?) ?? '',
      sellerId: (data['sellerId'] as String?) ?? '',
      sellerName: (data['sellerName'] as String?) ?? '',
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageSenderId: (data['lastMessageSenderId'] as String?) ?? '',
      lastMessageAt: (data['lastMessageAt'] is Timestamp)
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      buyerLastReadAt: (data['buyerLastReadAt'] is Timestamp)
          ? (data['buyerLastReadAt'] as Timestamp).toDate()
          : null,
      sellerLastReadAt: (data['sellerLastReadAt'] is Timestamp)
          ? (data['sellerLastReadAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
  }

  /// The other participant's name, from [viewerId]'s point of view —
  /// what the conversations list should actually show as the thread title.
  String otherPartyName(String viewerId) => viewerId == buyerId ? sellerName : buyerName;

  bool isUnreadFor(String viewerId) {
    if (lastMessageSenderId == viewerId) return false; // you sent the last message
    final lastRead = viewerId == buyerId ? buyerLastReadAt : sellerLastReadAt;
    if (lastRead == null) return true;
    return lastMessageAt.isAfter(lastRead);
  }
}
