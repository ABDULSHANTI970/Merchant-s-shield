import '../core/constants.dart';
import '../models/product.dart';
import 'market_repository.dart';

/// Fixed in-memory product list — used automatically when Firebase isn't
/// configured yet (see main.dart), so `flutter run` shows a working
/// market screen on day one instead of a blank error screen.
class SampleMarketRepository implements MarketRepository {
  final List<Product> _products = List.generate(
    _sampleData.length,
    (i) => Product(
      id: 'sample-$i',
      name: _sampleData[i]['name'] as String,
      category: _sampleData[i]['category'] as String,
      price: _sampleData[i]['price'] as double,
      priceUnit: _sampleData[i]['priceUnit'] as String,
      quantityAvailable: _sampleData[i]['qty'] as double,
      description: _sampleData[i]['description'] as String,
      imageUrl: '',
      sellerId: 'demo-seller-${i % 3}',
      sellerName: _sampleData[i]['seller'] as String,
      sellerPhone: '+970599000${100 + i}',
      location: _sampleData[i]['location'] as String,
      updatedAt: DateTime.now().subtract(Duration(hours: i)),
    ),
  );

  @override
  Stream<List<Product>> watchProducts({String? category}) {
    final filtered = (category == null || category == ProductCategory.all)
        ? _products
        : _products.where((p) => p.category == category).toList();
    return Stream.value(filtered);
  }

  @override
  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
  }

  static final List<Map<String, Object>> _sampleData = [
    {
      'name': 'اسمنت بورتلاندي رمادي',
      'category': ProductCategory.cement,
      'price': 32.0,
      'priceUnit': 'طن',
      'qty': 500.0,
      'description': 'اسمنت مطابق للمواصفات، تعبئة أكياس 50 كغم.',
      'seller': 'مؤسسة النور لمواد البناء',
      'location': 'غزة - الزيتون',
    },
    {
      'name': 'حديد تسليح 12 ملم',
      'category': ProductCategory.steel,
      'price': 780.0,
      'priceUnit': 'طن',
      'qty': 120.0,
      'description': 'حديد تسليح درجة أولى، قياس 12 ملم، طول 12 متر.',
      'seller': 'شركة الأمل للحديد',
      'location': 'غزة - الشيخ رضوان',
    },
    {
      'name': 'رمل بناء مغسول',
      'category': ProductCategory.sand,
      'price': 18.0,
      'priceUnit': 'م³',
      'qty': 300.0,
      'description': 'رمل مغسول مناسب للخلطات الإسمنتية والبلاستر.',
      'seller': 'مقلع الوادي',
      'location': 'خان يونس',
    },
    {
      'name': 'حصمة بناء مجروشة',
      'category': ProductCategory.gravel,
      'price': 16.5,
      'priceUnit': 'م³',
      'qty': 250.0,
      'description': 'حصمة مقاس 3/4 مناسبة للخرسانة المسلحة.',
      'seller': 'مقلع الوادي',
      'location': 'خان يونس',
    },
    {
      'name': 'بلوك أسمنتي 20 سم',
      'category': ProductCategory.blocks,
      'price': 0.85,
      'priceUnit': 'قطعة',
      'qty': 5000.0,
      'description': 'بلوك أسمنتي مفرغ، مقاس 20×20×40 سم.',
      'seller': 'مصنع الرواد',
      'location': 'رفح',
    },
    {
      'name': 'بلاط أرضيات داخلي',
      'category': ProductCategory.tiles,
      'price': 4.2,
      'priceUnit': 'م²',
      'qty': 800.0,
      'description': 'بلاط بورسلان مقاس 60×60، تشطيب مطفي.',
      'seller': 'معرض دار الديكور',
      'location': 'دير البلح',
    },
  ];
}
