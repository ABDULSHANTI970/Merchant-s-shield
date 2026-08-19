import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/conversation.dart';
import '../../models/product.dart';
import '../../services/auth_repository.dart';
import '../../services/chat_repository.dart';
import '../../services/market_repository.dart';
import '../../services/order_repository.dart';
import '../../services/storage_repository.dart';
import '../auth/login_screen.dart';
import '../chat/conversations_list_screen.dart';
import '../checkout/orders_list_screen.dart';
import '../profile/profile_screen.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'widgets/category_filter.dart';
import 'widgets/product_card.dart';

/// Feature #1–#4 from the investor deck: live pricing, search + category
/// filter, and tapping through to full product detail. Also hosts the
/// entry points for #3 (add product), #11 (my orders), #12 (chat), and
/// account access — all of which need to know who's signed in via
/// [authRepository].
///
/// [repository] is injected rather than constructed here — see
/// lib/services/market_repository.dart for why (Firestore vs. sample data).
/// [connectionBanner], if given, is shown pinned under the search bar (used
/// by main.dart to say "demo mode" when Firebase isn't configured yet).
class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.repository,
    required this.authRepository,
    required this.chatRepository,
    required this.storageRepository,
    required this.orderRepository,
    this.connectionBanner,
  });

  final MarketRepository repository;
  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final StorageRepository storageRepository;
  final OrderRepository orderRepository;
  final Widget? connectionBanner;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _category = ProductCategory.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سوق درع التاجر'),
        actions: [
          IconButton(
            tooltip: 'إضافة منتج',
            onPressed: () => _handleAddProduct(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
          _ChatAction(
            authRepository: widget.authRepository,
            chatRepository: widget.chatRepository,
            storageRepository: widget.storageRepository,
          ),
          _OrdersAction(authRepository: widget.authRepository, orderRepository: widget.orderRepository),
          _AccountAction(authRepository: widget.authRepository),
        ],
      ),
      body: Column(
        children: [
          if (widget.connectionBanner != null) widget.connectionBanner!,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج، مثال: اسمنت',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
              ),
            ),
          ),
          CategoryFilter(
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: widget.repository.watchProducts(category: _category),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(message: '${snapshot.error}');
                }

                final products = (snapshot.data ?? const [])
                    .where((p) => _matchesSearch(p, _searchQuery))
                    .toList();

                if (products.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: product,
                            authRepository: widget.authRepository,
                            chatRepository: widget.chatRepository,
                            storageRepository: widget.storageRepository,
                            orderRepository: widget.orderRepository,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Product p, String query) {
    if (query.isEmpty) return true;
    return p.name.toLowerCase().contains(query.toLowerCase());
  }

  /// "إضافة منتج جديد" needs a signed-in trader. If nobody's signed in,
  /// send them to [LoginScreen] first — [LoginScreen] pops itself once
  /// sign-in succeeds, and we then check [currentUser] again and continue
  /// straight into [AddProductScreen] so it doesn't take two taps.
  Future<void> _handleAddProduct(BuildContext context) async {
    var user = widget.authRepository.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(authRepository: widget.authRepository)),
      );
      user = widget.authRepository.currentUser;
    }
    if (user == null || !context.mounted) return; // user backed out of login
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          repository: widget.repository,
          storageRepository: widget.storageRepository,
          user: user!,
        ),
      ),
    );
  }
}

/// AppBar icon that shows a person outline when signed out (tap → login)
/// and the trader's initial when signed in (tap → profile).
class _AccountAction extends StatelessWidget {
  const _AccountAction({required this.authRepository});
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authRepository.authStateChanges(),
      initialData: authRepository.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return IconButton(
            tooltip: 'تسجيل الدخول',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepository)),
            ),
          );
        }
        final initial = user.label.isNotEmpty ? user.label.substring(0, 1) : '؟';
        return IconButton(
          tooltip: user.label,
          icon: CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.gold,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(
                    initial,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                  )
                : null,
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(authRepository: authRepository, user: user),
            ),
          ),
        );
      },
    );
  }
}

/// AppBar icon for "محادثاتي" (feature #12 entry point). Shows a small
/// gold dot when at least one conversation has an unread message. Hidden
/// behind a login prompt when signed out, same pattern as the add-product
/// button — browsing chat threads without an identity doesn't mean anything.
class _ChatAction extends StatelessWidget {
  const _ChatAction({
    required this.authRepository,
    required this.chatRepository,
    required this.storageRepository,
  });

  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final StorageRepository storageRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authRepository.authStateChanges(),
      initialData: authRepository.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return IconButton(
            tooltip: 'محادثاتي',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepository)),
            ),
          );
        }

        return StreamBuilder<List<Conversation>>(
          stream: chatRepository.watchConversations(user.uid),
          builder: (context, chatSnapshot) {
            final hasUnread =
                (chatSnapshot.data ?? const []).any((c) => c.isUnreadFor(user.uid));
            return IconButton(
              tooltip: 'محادثاتي',
              icon: Badge(
                isLabelVisible: hasUnread,
                smallSize: 9,
                backgroundColor: AppColors.gold,
                child: const Icon(Icons.forum_outlined),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationsListScreen(
                    chatRepository: chatRepository,
                    storageRepository: storageRepository,
                    currentUser: user,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// AppBar icon for "طلباتي" (feature #11 entry point — order/transaction
/// history). Same login-gated pattern as chat and add-product.
class _OrdersAction extends StatelessWidget {
  const _OrdersAction({required this.authRepository, required this.orderRepository});

  final AuthRepository authRepository;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authRepository.authStateChanges(),
      initialData: authRepository.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return IconButton(
          tooltip: 'طلباتي',
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () {
            if (user == null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepository)),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrdersListScreen(orderRepository: orderRepository, currentUser: user),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('ما في نتائج مطابقة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'جرّب كلمة بحث ثانية أو غيّر الفئة',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('صار في خطأ بتحميل السوق', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
