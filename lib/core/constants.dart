/// Product categories shown in the market filter chips.
/// Keep this list in sync with whatever the admin dashboard (Phase 5)
/// lets admins manage — for now it's a fixed starter list.
class ProductCategory {
  ProductCategory._();

  static const all = 'الكل';
  static const cement = 'اسمنت';
  static const steel = 'حديد';
  static const sand = 'رمل';
  static const gravel = 'حصمة';
  static const blocks = 'بلوك';
  static const tiles = 'بلاط';
  static const other = 'أخرى';

  static const List<String> values = [
    all,
    cement,
    steel,
    sand,
    gravel,
    blocks,
    tiles,
    other,
  ];
}

/// Firestore collection / field names in one place so a rename is a
/// one-line change instead of a project-wide find/replace.
class FirestorePaths {
  FirestorePaths._();

  static const products = 'products';
}
