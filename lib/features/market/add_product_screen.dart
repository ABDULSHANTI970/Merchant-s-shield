import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../services/market_repository.dart';
import '../../services/storage_repository.dart';
import '../shared/image_picker_field.dart';

/// Feature #3 — "إضافة منتج جديد: أي تاجر يقدر يضيف منتج للسوق مع السعر
/// والكمية". Only reachable once a trader is signed in (see
/// MarketScreen._handleAddProduct) — seller identity comes straight from
/// [user], not from a free-text field, so listings can't be spoofed.
/// Phase 4 adds the actual photo upload (feature #34) via [storageRepository].
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    required this.repository,
    required this.storageRepository,
    required this.user,
  });

  final MarketRepository repository;
  final StorageRepository storageRepository;
  final AppUser user;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceUnitController = TextEditingController(text: 'طن');
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();

  String _category = ProductCategory.cement;
  String _imageUrl = '';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sellerNameController.text = widget.user.displayName ?? '';
    _sellerPhoneController.text = widget.user.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final product = Product(
        id: '', // ignored on create — Firestore assigns the doc id
        name: _nameController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        priceUnit: _priceUnitController.text.trim(),
        quantityAvailable: double.parse(_quantityController.text.trim()),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl, // set by ImagePickerTile once upload finishes; empty is fine (shows placeholder)
        sellerId: widget.user.uid,
        sellerName: _sellerNameController.text.trim(),
        sellerPhone: _sellerPhoneController.text.trim(),
        location: _locationController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await widget.repository.addProduct(product);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المنتج للسوق.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'تعذّرت إضافة المنتج. تأكد من الاتصال وحاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ImagePickerTile(
                  storageRepository: widget.storageRepository,
                  // Timestamped so re-picking a photo before submitting
                  // doesn't overwrite a still-uploading previous attempt.
                  storagePath:
                      'products/${widget.user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                  onUploaded: (url) => setState(() => _imageUrl = url),
                  size: 110,
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'صورة المنتج (اختياري)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
                validator: _required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: ProductCategory.values
                    .where((c) => c != ProductCategory.all)
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'السعر (\$)'),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceUnitController,
                      decoration: const InputDecoration(labelText: 'الوحدة'),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الكمية المتاحة'),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'الموقع', hintText: 'مثال: غزة - الرمال'),
                validator: _required,
              ),
              const SizedBox(height: 22),
              Text('بيانات التواصل', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sellerNameController,
                decoration: const InputDecoration(labelText: 'اسم التاجر / الشركة'),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sellerPhoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رقم التواصل'),
                validator: _required,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('نشر المنتج بالسوق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null;

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'مطلوب';
    if (double.tryParse(v.trim()) == null) return 'أدخل رقمًا صحيحًا';
    return null;
  }
}
