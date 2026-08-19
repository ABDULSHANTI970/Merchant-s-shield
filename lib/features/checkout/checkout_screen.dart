import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_repository.dart';

/// Feature #6 (Escrow) + #7 (PayTabs, 100%/30% عربون) + #9 (عمولة 2%).
///
/// **What this screen actually does vs. what it explains it doesn't do:**
/// Tapping "ادفع الآن" creates an [Order] record in Firestore at
/// `OrderStatus.pendingPayment` — that part is real. It does NOT charge a
/// card or move any money, because that requires a server-side PayTabs
/// integration (Cloud Functions with the merchant secret key, webhook
/// signature verification, etc.) that has to be built and security-reviewed
/// separately — see functions/index.js for exactly where that plugs in.
/// Faking a "payment successful" screen here would be actively
/// misleading about whether money safety has been handled, so instead
/// this is upfront about the boundary with the person testing it.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.product,
    required this.buyer,
    required this.orderRepository,
  });

  final Product product;
  final AppUser buyer;
  final OrderRepository orderRepository;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  double _quantity = 1;
  PaymentPlan _plan = PaymentPlan.full;
  bool _submitting = false;
  String? _createdOrderId;

  double get _totalAmount => widget.product.price * _quantity;
  double get _chargeNow => _plan == PaymentPlan.deposit ? _totalAmount * 0.30 : _totalAmount;
  double get _commission => _totalAmount * Order.commissionRate;

  Future<void> _placeOrder() async {
    setState(() => _submitting = true);
    try {
      final order = Order(
        id: '',
        productId: widget.product.id,
        productName: widget.product.name,
        unitPrice: widget.product.price,
        quantity: _quantity,
        buyerId: widget.buyer.uid,
        buyerName: widget.buyer.label,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        paymentPlan: _plan,
        status: OrderStatus.pendingPayment,
        createdAt: DateTime.now(),
      );
      final id = await widget.orderRepository.createOrder(order);
      if (mounted) setState(() => _createdOrderId = id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر إنشاء الطلب. حاول مرة ثانية.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'ar', symbol: r'$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الشراء')),
      body: _createdOrderId != null
          ? _PendingPaymentNotice(orderId: _createdOrderId!)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${fmt.format(widget.product.price)} / ${widget.product.priceUnit}',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text('الكمية', style: Theme.of(context).textTheme.bodyMedium),
                              const Spacer(),
                              IconButton(
                                onPressed: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(_quantity.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                onPressed: () => setState(() => _quantity += 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('طريقة الدفع', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...PaymentPlan.values.map(
                    (plan) => RadioListTile<PaymentPlan>(
                      value: plan,
                      groupValue: _plan,
                      onChanged: (v) => setState(() => _plan = v ?? _plan),
                      title: Text(plan.arabicLabel),
                      subtitle: Text(
                        plan == PaymentPlan.deposit
                            ? 'ادفع ${fmt.format(_totalAmount * 0.30)} الآن، والباقي عند الاستلام'
                            : 'ادفع كامل المبلغ الآن',
                        style: const TextStyle(fontSize: 12),
                      ),
                      activeColor: AppColors.navy,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _EscrowExplainer(),
                  const SizedBox(height: 18),
                  _SummaryRow(label: 'إجمالي الصفقة', value: fmt.format(_totalAmount)),
                  _SummaryRow(
                    label: 'عمولة المنصة (${(Order.commissionRate * 100).toStringAsFixed(0)}%)',
                    value: fmt.format(_commission),
                    muted: true,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(label: 'المطلوب دفعه الآن', value: fmt.format(_chargeNow), emphasize: true),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _submitting ? null : _placeOrder,
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
                        : const Text('ادفع الآن'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EscrowExplainer extends StatelessWidget {
  const _EscrowExplainer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.navy),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'فلوسك بتنحجز بأمان لدى المنصة ولا توصل للتاجر إلا بعد ما تأكّد استلام البضاعة.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.muted = false, this.emphasize = false});

  final String label;
  final String value;
  final bool muted;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? AppColors.gold : (muted ? AppColors.textMuted : AppColors.textPrimary),
              fontSize: emphasize ? 17 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after the order record is created — honest about the fact that
/// no real payment gateway is wired up yet in this phase.
class _PendingPaymentNotice extends StatelessWidget {
  const _PendingPaymentNotice({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_outlined, size: 46, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('تم إنشاء الطلب', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'رقم الطلب: $orderId',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'ملاحظة للمطوّر: هاي المرحلة بتسجّل نية الشراء بس — بوابة الدفع الفعلية '
                '(PayTabs) لسه مو مربوطة، لأنها تحتاج مفاتيح API حقيقية ومراجعة أمان من '
                'طرف السيرفر (Cloud Functions) قبل ما تشتغل بفلوس حقيقية. التفاصيل '
                'والخطوات موجودة بـ functions/index.js وREADME.md.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('رجوع للسوق'),
            ),
          ],
        ),
      ),
    );
  }
}
