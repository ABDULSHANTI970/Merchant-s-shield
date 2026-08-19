import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';

/// Feature #11 — "سجل المعاملات: كل تاجر يشوف كل دفعاته وحالة كل صفقة".
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key, required this.orderRepository, required this.currentUser});

  final OrderRepository orderRepository;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: StreamBuilder<List<Order>>(
        stream: orderRepository.watchOrders(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('ما عندك طلبات بعد', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final isBuyer = order.buyerId == currentUser.uid;
              return _OrderCard(order: order, isBuyer: isBuyer, orderRepository: orderRepository);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.isBuyer, required this.orderRepository});

  final Order order;
  final bool isBuyer;
  final OrderRepository orderRepository;

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pendingPayment:
        return AppColors.gold;
      case OrderStatus.paid:
      case OrderStatus.shipped:
        return AppColors.navy;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.refunded:
      case OrderStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'ar', symbol: r'$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.productName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.arabicLabel,
                    style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBuyer ? 'من: ${order.sellerName}' : 'إلى: ${order.buyerName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  fmt.format(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 15),
                ),
                const SizedBox(width: 6),
                Text('· ${order.paymentPlan.arabicLabel}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                const Spacer(),
                if (isBuyer && order.status == OrderStatus.pendingPayment)
                  TextButton(
                    onPressed: () => orderRepository.cancelPendingOrder(order.id),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
