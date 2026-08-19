import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'core/theme.dart';
import 'features/market/market_screen.dart';
import 'services/auth_repository.dart';
import 'services/chat_repository.dart';
import 'services/market_repository.dart';
import 'services/order_repository.dart';
import 'services/storage_repository.dart';

class TajerShieldApp extends StatelessWidget {
  const TajerShieldApp({
    super.key,
    required this.repository,
    required this.authRepository,
    required this.chatRepository,
    required this.storageRepository,
    required this.orderRepository,
    required this.isDemoMode,
  });

  final MarketRepository repository;
  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final StorageRepository storageRepository;
  final OrderRepository orderRepository;
  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    // Lets NumberFormat/DateFormat default to Arabic formatting anywhere
    // they're used without an explicit `locale:` argument. The explicit
    // locale:'ar' calls already in product_card.dart etc. still need
    // initializeDateFormatting('ar') to have run first — see main.dart.
    Intl.defaultLocale = 'ar';

    return MaterialApp(
      title: 'درع التاجر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),

      // Arabic-first. When the English UI is added (feature #30 — تعدد
      // اللغات) this is where `Locale('en')` joins the supported list.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: MarketScreen(
        repository: repository,
        authRepository: authRepository,
        chatRepository: chatRepository,
        storageRepository: storageRepository,
        orderRepository: orderRepository,
        connectionBanner: isDemoMode ? const _DemoModeBanner() : null,
      ),
    );
  }
}

/// Shown when Firebase couldn't be reached, so it's obvious the data on
/// screen is sample data and not the real live market.
class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gold.withOpacity(0.14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'وضع تجريبي — لم يتم الاتصال بـ Firebase بعد، البيانات المعروضة تجريبية.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
