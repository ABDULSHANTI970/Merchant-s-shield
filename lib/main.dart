import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/auth_repository.dart';
import 'services/chat_repository.dart';
import 'services/disabled_auth_repository.dart';
import 'services/disabled_storage_repository.dart';
import 'services/firebase_auth_repository.dart';
import 'services/firebase_storage_repository.dart';
import 'services/firestore_chat_repository.dart';
import 'services/firestore_market_repository.dart';
import 'services/firestore_order_repository.dart';
import 'services/market_repository.dart';
import 'services/order_repository.dart';
import 'services/sample_chat_repository.dart';
import 'services/sample_market_repository.dart';
import 'services/sample_order_repository.dart';
import 'services/storage_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chat/conversation timestamps and price formatting use 'ar' explicitly
  // (see DateFormat.Hm('ar') in chat_screen.dart / conversations_list_screen.dart
  // and NumberFormat.currency(locale: 'ar', ...) in product/checkout screens)
  // — intl needs this called once before any of that runs, or it throws at
  // runtime instead of just falling back to a default locale.
  await initializeDateFormatting('ar');

  MarketRepository repository;
  AuthRepository authRepository;
  ChatRepository chatRepository;
  StorageRepository storageRepository;
  OrderRepository orderRepository;
  bool isDemoMode;

  try {
    // Before this works you need to either:
    //   (a) run `flutterfire configure` (generates firebase_options.dart,
    //       then pass DefaultFirebaseOptions.currentPlatform below), or
    //   (b) drop google-services.json / GoogleService-Info.plist into the
    //       native android/ios folders and call Firebase.initializeApp()
    //       with no arguments, as done here.
    // See README.md → "ربط Firebase" for the full walkthrough. Phase 2 also
    // needs Email/Password, Phone, and Google enabled under Firebase
    // Console → Authentication → Sign-in method — see README.md → "تفعيل
    // طرق تسجيل الدخول". Phase 4 needs a Firebase Storage bucket created
    // (Firebase Console → Storage → Get started) with storage.rules deployed.
    // Phase 5 (orders/Escrow) needs firestore.rules redeployed too — the
    // client only ever creates orders as pendingPayment; see
    // lib/services/order_repository.dart and functions/index.js for why
    // real payment status changes deliberately do NOT happen from here.
    await Firebase.initializeApp();
    repository = FirestoreMarketRepository();
    authRepository = FirebaseAuthRepository();
    chatRepository = FirestoreChatRepository();
    storageRepository = FirebaseStorageRepository();
    orderRepository = FirestoreOrderRepository();
    isDemoMode = false;
  } catch (e) {
    // No Firebase project wired up yet — fall back to sample data (and
    // disabled auth/storage repositories that explain themselves instead
    // of crashing) so the UI is still fully usable while that's being set up.
    debugPrint('Firebase init failed, using sample data instead: $e');
    repository = SampleMarketRepository();
    authRepository = DisabledAuthRepository();
    chatRepository = SampleChatRepository();
    storageRepository = DisabledStorageRepository();
    orderRepository = SampleOrderRepository();
    isDemoMode = true;
  }

  runApp(TajerShieldApp(
    repository: repository,
    authRepository: authRepository,
    chatRepository: chatRepository,
    storageRepository: storageRepository,
    orderRepository: orderRepository,
    isDemoMode: isDemoMode,
  ));
}
