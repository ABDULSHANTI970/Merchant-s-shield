import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'storage_repository.dart';

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadImage({required String path, required Uint8List bytes}) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }
}
