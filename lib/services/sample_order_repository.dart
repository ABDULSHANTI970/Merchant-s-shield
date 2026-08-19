import 'dart:async';

import '../models/order.dart';
import 'order_repository.dart';

/// Demo-mode orders, same pattern as the other Sample*Repository classes.
class SampleOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};
  final _controller = StreamController<void>.broadcast();
  int _idCounter = 0;

  @override
  Stream<List<Order>> watchOrders(String uid) async* {
    List<Order> current() =>
        _orders.values.where((o) => o.buyerId == uid || o.sellerId == uid).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    yield current();
    yield* _controller.stream.map((_) => current());
  }

  @override
  Future<String> createOrder(Order order) async {
    final id = 'demo-order-${_idCounter++}';
    _orders[id] = Order(
      id: id,
      productId: order.productId,
      productName: order.productName,
      unitPrice: order.unitPrice,
      quantity: order.quantity,
      buyerId: order.buyerId,
      buyerName: order.buyerName,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      paymentPlan: order.paymentPlan,
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
    );
    _controller.add(null);
    return id;
  }

  @override
  Future<void> cancelPendingOrder(String orderId) async {
    final existing = _orders[orderId];
    if (existing == null || existing.status != OrderStatus.pendingPayment) return;
    _orders[orderId] = Order(
      id: existing.id,
      productId: existing.productId,
      productName: existing.productName,
      unitPrice: existing.unitPrice,
      quantity: existing.quantity,
      buyerId: existing.buyerId,
      buyerName: existing.buyerName,
      sellerId: existing.sellerId,
      sellerName: existing.sellerName,
      paymentPlan: existing.paymentPlan,
      status: OrderStatus.cancelled,
      createdAt: existing.createdAt,
    );
    _controller.add(null);
  }
}
