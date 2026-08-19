import '../models/product.dart';

/// Anything that can supply a live list of market products implements this.
///
/// Why an interface instead of calling Firestore straight from the UI:
/// the market screen shouldn't care *where* products come from. Today
/// that's [FirestoreMarketRepository]; if Firebase isn't configured yet
/// on a fresh checkout, [SampleMarketRepository] lets the UI still be
/// built and demoed. Later phases (offers, escrow) can add methods here
/// without touching any widget code.
abstract class MarketRepository {
  /// Streams the live product list, optionally narrowed to [category].
  /// Pass null or [ProductCategory.all] for every category.
  Stream<List<Product>> watchProducts({String? category});

  /// Adds a new product listing (feature #3 — "إضافة منتج جديد").
  Future<void> addProduct(Product product);
}
