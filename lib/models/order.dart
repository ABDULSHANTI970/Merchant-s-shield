import 'package:cloud_firestore/cloud_firestore.dart';

/// Escrow deal lifecycle. Deliberately a SMALL set of states, and — this
/// matters — most of these transitions are NOT meant to be writable by
/// the client directly. See the long comment on [OrderRepository] and
/// firestore.rules for exactly which transitions the client is trusted
/// to make vs. which require a signed PayTabs webhook through Cloud
/// Functions.
enum OrderStatus {
  pendingPayment, // order created, waiting for the buyer to actually pay
  paid, // PayTabs confirmed payment; funds held in escrow (feature #6)
  shipped,
  delivered, // buyer confirmed receipt; triggers seller payout minus 2% (feature #8)
  refunded, // feature #10 — "نظام المرتجعات"
  cancelled; // buyer backed out before paying — nothing ever moved

  String get arabicLabel {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'بانتظار الدفع';
      case OrderStatus.paid:
        return 'مدفوع (بالضمان)';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم الاستلام';
      case OrderStatus.refunded:
        return 'مسترجع';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pendingPayment,
    );
  }
}

enum PaymentPlan {
  full, // 100% now
  deposit; // 30% عربون — feature #7

  String get arabicLabel => this == PaymentPlan.full ? 'دفع كامل 100%' : 'عربون 30%';

  static PaymentPlan fromString(String value) {
    return value == 'deposit' ? PaymentPlan.deposit : PaymentPlan.full;
  }
}

/// One purchase, escrow-tracked from payment to delivery. Feature #6
/// (Escrow), #7 (PayTabs, full/deposit), #8 (auto-transfer minus 2%), #9
/// (platform commission wallet), #10 (returns), #11 (transaction history).
class Order {
  static const double commissionRate = 0.02; // 2% — feature #9

  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final PaymentPlan paymentPlan;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.paymentPlan,
    required this.status,
    required this.createdAt,
  });

  double get totalAmount => unitPrice * quantity;

  /// What's actually charged now — full price, or the 30% deposit.
  double get chargeNowAmount => paymentPlan == PaymentPlan.deposit ? totalAmount * 0.30 : totalAmount;

  double get commissionAmount => totalAmount * commissionRate;

  /// What the seller receives once delivery is confirmed (feature #8).
  double get sellerPayoutAmount => totalAmount - commissionAmount;

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Order(
      id: doc.id,
      productId: (data['productId'] as String?) ?? '',
      productName: (data['productName'] as String?) ?? '',
      unitPrice: _toDouble(data['unitPrice']),
      quantity: _toDouble(data['quantity']),
      buyerId: (data['buyerId'] as String?) ?? '',
      buyerName: (data['buyerName'] as String?) ?? '',
      sellerId: (data['sellerId'] as String?) ?? '',
      sellerName: (data['sellerName'] as String?) ?? '',
      paymentPlan: PaymentPlan.fromString((data['paymentPlan'] as String?) ?? 'full'),
      status: OrderStatus.fromString((data['status'] as String?) ?? 'pendingPayment'),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Only used for the INITIAL create — see the "client-writable fields"
  /// note in OrderRepository. Never used to write a status transition.
  Map<String, dynamic> toCreateMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'paymentPlan': paymentPlan == PaymentPlan.deposit ? 'deposit' : 'full',
      'status': 'pendingPayment',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(Object? v) => v is num ? v.toDouble() : 0;
}
