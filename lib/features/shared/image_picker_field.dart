import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/storage_repository.dart';

/// Self-contained "tap to add a photo" tile: shows a placeholder, opens
/// a camera/gallery picker sheet (feature #34 — "من الكاميرا او
/// الاستوديو"), uploads via [storageRepository], then shows the result
/// and calls [onUploaded] with the download URL. One widget covers both
/// the product-photo use case (AddProductScreen) and chat attachments,
/// so the upload/error/progress handling only exists in one place.
class ImagePickerTile extends StatefulWidget {
  const ImagePickerTile({
    super.key,
    required this.storageRepository,
    required this.storagePath,
    required this.onUploaded,
    this.size = 96,
  });

  final StorageRepository storageRepository;

  /// Full Storage path for this specific upload, e.g.
  /// `products/{uid}/{timestamp}.jpg`. Built by the caller so naming stays
  /// scoped correctly (see AddProductScreen / ChatScreen composer).
  final String storagePath;

  final ValueChanged<String> onUploaded;
  final double size;

  @override
  State<ImagePickerTile> createState() => _ImagePickerTileState();
}

class _ImagePickerTileState extends State<ImagePickerTile> {
  Uint8List? _previewBytes;
  bool _uploading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 82, maxWidth: 1600);
      if (file == null) return; // user cancelled

      final bytes = await file.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _uploading = true;
      });

      final url = await widget.storageRepository.uploadImage(path: widget.storagePath, bytes: bytes);
      widget.onUploaded(url);
    } catch (e) {
      setState(() => _error = 'تعذّر رفع الصورة. حاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.navy),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.navy),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _uploading ? null : _showSourceSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              image: _previewBytes != null
                  ? DecorationImage(image: MemoryImage(_previewBytes!), fit: BoxFit.cover)
                  : null,
            ),
            child: _uploading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : (_previewBytes == null
                    ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted)
                    : null),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 11.5)),
        ],
      ],
    );
  }
}
