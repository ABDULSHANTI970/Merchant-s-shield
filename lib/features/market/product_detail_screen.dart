import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/auth_repository.dart';
import '../../services/chat_repository.dart';
import '../../services/order_repository.dart';
import '../../services/storage_repository.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../checkout/checkout_screen.dart';

/// Feature #4 — "عرض تفاصيل المنتج: صورة + وصف + رقم التاجر + الموقع".
/// Feature #5 ("اطلب عرض سعر") wired to the real chat flow (Phase 3).
/// Feature #6/#7 ("إتمام الشراء") wired to the checkout flow (Phase 5) —
/// see [_startCheckout] and the honest disclosure inside CheckoutScreen
/// about what payment processing does/doesn't actually happen yet.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.authRepository,
    required this.chatRepository,
    required this.storageRepository,
    required this.orderRepository,
  });

  final Product product;
  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final StorageRepository storageRepository;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(locale: 'ar', symbol: r'$', decimalDigits: 2);
    final isOwnProduct = authRepository.currentUser?.uid == product.sellerId;

    return Scaffold(
      appBar: AppBar(title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(product.location, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Divider(height: 32),
            Text(
              '${priceFmt.format(product.price)} / ${product.priceUnit}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 4),
            Text(
              'الكمية المتاحة: ${product.quantityAvailable.toStringAsFixed(0)} ${product.priceUnit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text('الوصف', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              product.description.isEmpty ? 'لا يوجد وصف من التاجر.' : product.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            Text('التاجر', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _SellerCard(name: product.sellerName, phone: product.sellerPhone),
            const SizedBox(height: 24),
            if (isOwnProduct)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'هذا منتجك — ما بتقدر تطلب عرض سعر أو تشتري منتجك أنت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startCheckout(context),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('إتمام الشراء — دفع آمن (Escrow)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _requestOffer(context),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('اطلب عرض سعر بدل الشراء المباشر'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: product.imageUrl.isEmpty
            ? Container(
                color: AppColors.surfaceAlt,
                child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
              )
            : Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceAlt,
                  child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textMuted),
                ),
              ),
      ),
    );
  }

  /// Feature #6/#7. Same "login first, then continue" pattern as the
  /// other gated actions in this app.
  Future<void> _startCheckout(BuildContext context) async {
    var user = authRepository.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepository)),
      );
      user = authRepository.currentUser;
    }
    if (user == null || !context.mounted) return; // backed out of login

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          product: product,
          buyer: user!,
          orderRepository: orderRepository,
        ),
      ),
    );
  }

  /// Feature #5. Needs a signed-in buyer — same "login first, then
  /// continue" pattern as MarketScreen._handleAddProduct. Once signed in,
  /// starts (or reopens) the conversation for this product and jumps
  /// straight into the chat.
  Future<void> _requestOffer(BuildContext context) async {
    var user = authRepository.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepository)),
      );
      user = authRepository.currentUser;
    }
    if (user == null || !context.mounted) return; // backed out of login

    try {
      final conversationId = await chatRepository.startConversation(product: product, buyer: user);
      if (!context.mounted) return;

      // We only have the id back — build a lightweight Conversation for
      // ChatScreen's header immediately instead of waiting on a fresh
      // stream read, so opening the chat feels instant.
      final conversation = await chatRepository
          .watchConversations(user.uid)
          .first
          .then((list) => list.firstWhere((c) => c.id == conversationId));

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRepository: chatRepository,
            storageRepository: storageRepository,
            currentUser: user!,
            conversation: conversation,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر فتح المحادثة. حاول مرة ثانية.')));
      }
    }
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.name, required this.phone});

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceAlt,
              child: Icon(Icons.storefront_outlined, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (phone.isNotEmpty)
                    Text(phone, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (phone.isNotEmpty)
              IconButton.filled(
                onPressed: () => _call(phone),
                icon: const Icon(Icons.call_outlined),
                style: IconButton.styleFrom(backgroundColor: AppColors.gold),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
