import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import 'order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  @override
  Stream<List<Order>> watchOrders(String uid) {
    // Same buyer-OR-seller merge pattern as FirestoreChatRepository.watchConversations
    // — Firestore can't OR two fields in one query.
    final buyerStream = _orders.where('buyerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
    final sellerStream =
        _orders.where('sellerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();

    late final StreamController<List<Order>> controller;
    List<Order> buyerList = [];
    List<Order> sellerList = [];
    var buyerReady = false;
    var sellerReady = false;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? buyerSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sellerSub;

    void emit() {
      if (!buyerReady || !sellerReady) return;
      final merged = <String, Order>{};
      for (final o in buyerList) {
        merged[o.id] = o;
      }
      for (final o in sellerList) {
        merged[o.id] = o;
      }
      final list = merged.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }

    controller = StreamController<List<Order>>.broadcast(
      onListen: () {
        buyerSub = buyerStream.listen((snap) {
          buyerList = snap.docs.map(Order.fromFirestore).toList();
          buyerReady = true;
          emit();
        }, onError: controller.addError);
        sellerSub = sellerStream.listen((snap) {
          sellerList = snap.docs.map(Order.fromFirestore).toList();
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
  Future<String> createOrder(Order order) async {
    final doc = await _orders.add(order.toCreateMap());
    return doc.id;
  }

  @override
  Future<void> cancelPendingOrder(String orderId) async {
    // firestore.rules only allows this exact transition (pendingPayment →
    // cancelled) from the client — anything else is rejected server-side
    // even if this method were called with different data.
    await _orders.doc(orderId).update({'status': 'cancelled'});
  }
}
