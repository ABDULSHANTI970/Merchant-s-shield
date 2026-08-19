import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/product.dart';
import 'market_repository.dart';

/// Live Firestore-backed market data (investor-deck feature #1: "سوق لحظي
/// للأسعار — أسعار شراء وبيع مواد البناء تتحدث مباشرة من Firebase").
class FirestoreMarketRepository implements MarketRepository {
  FirestoreMarketRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(FirestorePaths.products);

  @override
  Stream<List<Product>> watchProducts({String? category}) {
    Query<Map<String, dynamic>> query =
        _products.orderBy('updatedAt', descending: true);

    if (category != null && category != ProductCategory.all) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(Product.fromFirestore).toList(),
        );
  }

  @override
  Future<void> addProduct(Product product) {
    return _products.add(product.toMap());
  }
}
