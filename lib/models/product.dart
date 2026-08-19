import 'package:cloud_firestore/cloud_firestore.dart';

/// A single market listing — a trader's product with a live price.
///
/// Matches investor-deck features #1–#4 (live pricing, search/filter,
/// add product, product detail card). Payment/escrow fields belong to a
/// separate `orders` collection built in Phase 2 — this model stays
/// deliberately focused on "what's for sale", not "how it's paid for".
class Product {
  final String id;
  final String name;
  final String category;
  final double price; // price per unit, in USD or ILS — see [priceUnit]
  final String priceUnit; // e.g. "طن", "م3", "قطعة"
  final double quantityAvailable;
  final String description;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String location; // free-text city/area, e.g. "غزة - الرمال"
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.priceUnit,
    required this.quantityAvailable,
    required this.description,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.location,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'أخرى',
      price: _toDouble(data['price']),
      priceUnit: (data['priceUnit'] as String?) ?? 'وحدة',
      quantityAvailable: _toDouble(data['quantityAvailable']),
      description: (data['description'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      sellerId: (data['sellerId'] as String?) ?? '',
      sellerName: (data['sellerName'] as String?) ?? 'تاجر',
      sellerPhone: (data['sellerPhone'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'priceUnit': priceUnit,
      'quantityAvailable': quantityAvailable,
      'description': description,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return 0;
  }
}
