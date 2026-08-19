import 'dart:typed_data';

import 'storage_repository.dart';

/// Used instead of [FirebaseStorageRepository] when Firebase isn't
/// configured. There's no meaningful place to actually store the bytes,
/// so this throws a clear, catchable error instead of pretending to
/// succeed — callers (AddProductScreen, chat composer) already handle
/// upload failures gracefully.
class DisabledStorageRepository implements StorageRepository {
  @override
  Future<String> uploadImage({required String path, required Uint8List bytes}) async {
    throw Exception('رفع الصور غير متاح بالوضع التجريبي — يحتاج Firebase Storage مربوط فعليًا.');
  }
}
