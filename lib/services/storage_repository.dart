import 'dart:typed_data';

/// Uploads image bytes and returns a public download URL. Used by both
/// product photos (feature #34) and chat attachments (feature #13) — one
/// small interface instead of duplicating Storage calls in two features.
abstract class StorageRepository {
  /// [path] should be unique per upload, e.g.
  /// `products/{uid}/{timestamp}.jpg` or `chat/{conversationId}/{timestamp}.jpg`
  /// — see the `path` helpers where this is called for the actual scheme.
  Future<String> uploadImage({required String path, required Uint8List bytes});
}
