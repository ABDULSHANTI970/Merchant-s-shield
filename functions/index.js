/**
 * درع التاجر — Cloud Functions: Escrow / PayTabs skeleton
 * =========================================================
 *
 * READ THIS BEFORE DEPLOYING ANYTHING IN THIS FILE.
 *
 * What this file IS: a correct structural skeleton showing which server
 * functions need to exist, what each one is responsible for, and how they
 * connect to the Flutter app's `orders` collection and firestore.rules
 * (which deliberately blocks the client from writing order status directly
 * — see lib/services/order_repository.dart for that reasoning).
 *
 * What this file is NOT: a working PayTabs integration. The actual PayTabs
 * API calls (request/response shapes, endpoint paths, required headers,
 * and — critically — the exact webhook signature verification algorithm)
 * are deliberately left as TODOs with links to PayTabs' own docs, instead
 * of guessed/fabricated code. Getting webhook verification wrong is a real
 * security hole (it's what stops anyone on the internet from POSTing a
 * fake "payment succeeded" to your webhook URL and getting free escrow
 * releases), so that specific piece needs to be written against PayTabs'
 * CURRENT official documentation and tested with their sandbox — not
 * copied from a chat assistant that can't verify it live.
 *
 * Before this goes anywhere near real money:
 *   1. Get PayTabs sandbox credentials and read their current REST API +
 *      webhook docs: https://support.paytabs.com/
 *   2. Implement + test createPaymentSession and paytabsWebhook below
 *      against the SANDBOX environment first.
 *   3. Get a security review of the webhook signature verification
 *      specifically — that's the one piece that, if wrong, lets someone
 *      fake a payment.
 *   4. Only then swap sandbox credentials for production ones.
 */

const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const COMMISSION_RATE = 0.02; // feature #9 — keep in sync with lib/models/order.dart

/**
 * Called by the Flutter app once the buyer taps "ادفع الآن" on an existing
 * pendingPayment order (see CheckoutScreen — currently this function is
 * NOT actually wired up from the client; that's the honest boundary
 * mentioned in checkout_screen.dart).
 *
 * Responsible for:
 *   - Verifying the calling user really is the order's buyer.
 *   - Re-deriving the charge amount SERVER-SIDE from the order doc
 *     (never trust an amount the client sends you directly).
 *   - Calling PayTabs' "create payment page" API with that amount.
 *   - Returning the redirect URL for the app to open (e.g. in a WebView).
 */
exports.createPaymentSession = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "لازم تسجّل دخول أول.");
  }

  const {orderId} = request.data;
  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId مطلوب.");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "الطلب غير موجود.");
  }
  const order = orderSnap.data();

  if (order.buyerId !== uid) {
    throw new HttpsError("permission-denied", "هذا مو طلبك.");
  }
  if (order.status !== "pendingPayment") {
    throw new HttpsError("failed-precondition", "الطلب مو بحالة بانتظار الدفع.");
  }

  // Server-side amount derivation — do NOT trust a client-supplied amount.
  const totalAmount = order.unitPrice * order.quantity;
  const chargeNow = order.paymentPlan === "deposit" ? totalAmount * 0.30 : totalAmount;

  // TODO: replace with a real call to PayTabs' Create Payment Page API.
  // Needs: PayTabs profile ID + server key, stored ONLY in Cloud Functions
  // config (`firebase functions:config:set paytabs.server_key=...`), NEVER
  // in the Flutter app. Request should include: cart_amount=chargeNow,
  // cart_currency, cart_id=orderId, a return URL, and a callback/webhook
  // URL pointing at `paytabsWebhook` below. See PayTabs' "Hosted Payment
  // Page" docs for the exact fields — don't guess them here.
  throw new HttpsError(
      "unimplemented",
      "createPaymentSession لسه ما اتربط بـ PayTabs فعليًا — راجع التعليق " +
      "بأعلى الدالة والـ TODO جوّاها.",
  );
});

/**
 * PayTabs calls THIS endpoint (not the other way around) once a payment
 * finishes — success or failure. This is the ONLY place `status: 'paid'`
 * should ever get written, and only after the signature check passes.
 *
 * TODO before this is usable:
 *   1. Verify the request signature per PayTabs' current webhook docs.
 *      If verification fails, return 401 and do NOT touch Firestore.
 *      This is the single most important line of code in the whole
 *      payment flow — anyone who can skip it can fake a "payment succeeded"
 *      for free. Do not deploy this function without it implemented and
 *      tested.
 *   2. Look up the order by the cart_id / orderId PayTabs echoes back.
 *   3. On confirmed success: transaction-write status → 'paid', and
 *      increment a `platform_wallet` doc's balance by the order's
 *      commission amount (feature #9) — in the SAME transaction, so the
 *      two can't drift out of sync.
 */
exports.paytabsWebhook = onRequest(async (req, res) => {
  // TODO: signature verification goes here, BEFORE anything else runs.
  // const isValid = verifyPaytabsSignature(req);
  // if (!isValid) { res.status(401).send("invalid signature"); return; }

  res.status(501).send(
      "paytabsWebhook لسه ما اتربط فعليًا — لازم تتأكد من التوقيع (signature) " +
      "أول أي شي قبل ما تعتمد هالـ endpoint. راجع تعليق الدالة.",
  );
});

/**
 * Called by the BUYER from the app once they've physically received the
 * goods (feature #8 — "بعد تأكيد الاستلام الفلوس بتتحول للبائع").
 * This is a client-triggered CALL, but the actual Firestore write still
 * happens here server-side (via Admin SDK) — the client never writes
 * `status: 'delivered'` directly, matching firestore.rules.
 */
exports.confirmDelivery = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "لازم تسجّل دخول أول.");
  }
  const {orderId} = request.data;

  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    const order = snap.data();

    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "هذا مو طلبك.");
    }
    if (order.status !== "paid" && order.status !== "shipped") {
      throw new HttpsError("failed-precondition", "الطلب مو بحالة تسمح بتأكيد الاستلام.");
    }

    const totalAmount = order.unitPrice * order.quantity;
    const commission = totalAmount * COMMISSION_RATE;
    const sellerPayout = totalAmount - commission;

    tx.update(orderRef, {
      status: "delivered",
      deliveredAt: FieldValue.serverTimestamp(),
    });

    // TODO: this records the commission internally, but does NOT move
    // real money to the seller yet — an actual payout needs either
    // PayTabs' payout/transfer API or a manual admin payout flow. Track
    // that as its own explicit step; don't assume this Firestore write
    // means money has moved.
    const walletRef = db.collection("platform_wallet").doc("balance");
    tx.set(
        walletRef,
        {totalCommission: FieldValue.increment(commission)},
        {merge: true},
    );

    tx.set(db.collection("orders").doc(orderId).collection("_internal").doc("payout"), {
      sellerId: order.sellerId,
      amount: sellerPayout,
      status: "pending_manual_payout", // until a real payout integration exists
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

/**
 * Feature #10 — "نظام المرتجعات". Stubbed the same way: records the
 * request, does NOT move money. An admin (Phase 6 dashboard) or a
 * PayTabs refund API call is what would actually complete this.
 */
exports.requestRefund = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "لازم تسجّل دخول أول.");
  }
  const {orderId, reason} = request.data;

  const orderRef = db.collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "الطلب غير موجود.");
  }
  const order = snap.data();
  if (order.buyerId !== uid) {
    throw new HttpsError("permission-denied", "هذا مو طلبك.");
  }

  await db.collection("disputes").add({
    orderId,
    buyerId: uid,
    sellerId: order.sellerId,
    reason: reason || "",
    status: "open", // feature #24 — "مركز النزاعات" reads this in Phase 6
    createdAt: FieldValue.serverTimestamp(),
  });

  return {ok: true};
});
