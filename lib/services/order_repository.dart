import '../models/order.dart';

/// **Read this before touching Escrow code.**
///
/// Every other repository in this app (`MarketRepository`, `ChatRepository`,
/// ...) lets the signed-in user write pretty freely to THEIR OWN data.
/// Orders are different on purpose: once real money is involved, the
/// client app must NOT be trusted to declare "payment succeeded" or "funds
/// released to seller" — that has to come from a source only the server
/// controls (a signed webhook from PayTabs, verified inside a Cloud
/// Function using the Admin SDK, which bypasses Firestore security rules
/// entirely). A compromised or modified client build must not be able to
/// grant itself a "paid" order for free.
///
/// So this interface is intentionally narrow:
/// - [createOrder] — client can create an order, but ALWAYS starts at
///   `OrderStatus.pendingPayment`. No amount is charged yet.
/// - [watchOrders] — read-only, for "طلباتي" / order history (feature #11).
/// - [cancelPendingOrder] — the ONE status transition the client is
///   trusted to make directly, and only from `pendingPayment` (nothing
///   was ever charged, so there's nothing to protect).
///
/// Everything else — marking `paid`, `shipped`, `delivered`,
/// `refunded` — happens server-side. See functions/index.js for where
/// those transitions actually belong once a real payment gateway is
/// wired up, and firestore.rules for how the client is blocked from
/// writing those fields directly.
abstract class OrderRepository {
  Stream<List<Order>> watchOrders(String uid);

  /// Records purchase intent. Does NOT charge any money — see
  /// [CheckoutScreen] for why, and what happens (or rather, what
  /// currently does NOT happen) after this call.
  Future<String> createOrder(Order order);

  Future<void> cancelPendingOrder(String orderId);
}
