import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';
import '../models.dart';
import '../providers.dart';
import '../services.dart';
import '../widgets.dart';
import 'order_screens.dart';
import 'profile_screens.dart';

// ==================== MAIN NAV ====================
class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});
  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
  }

  Future<void> _setupNotifications() async {
    try {
      await NotificationService.initialize();
      final uid = AuthService.uid;
      final token = await NotificationService.getToken();
      if (uid != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: index,
                  children: const [
                    HomeScreen(),
                    MenuScreen(),
                    CartScreen(),
                    OrdersScreen(),
                    ProfileScreen(),
                  ],
                ),
                if (index != 2)
                  const Positioned(
                      left: 0, right: 0, bottom: 0, child: CartBar()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(navIndexProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ==================== DEAL SHEET ====================
void showDealSheet(BuildContext context, WidgetRef ref, DealModel d) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            Text(d.title, style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text(d.description,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Text(Formatters.price(d.price),
                style: AppTextStyles.price.copyWith(color: AppColors.primary)),
            const SizedBox(height: 18),
            AppButton(
              text: 'Add to Cart',
              icon: Icons.add_shopping_cart,
              onPressed: () {
                ref.read(cartProvider.notifier).add(CartItemModel(
                      productId: 'deal_${d.id}',
                      name: d.title,
                      imagePath: d.imagePath,
                      unitPrice: d.price,
                      instruction: d.description,
                    ));
                Navigator.pop(ctx);
                Helpers.success(context, '${d.title} added to cart');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ==================== HOME ====================
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final deals = ref.watch(dealsProvider);
    final popular = ref.watch(popularProductsProvider);

    final announcementsAsync = ref.watch(announcementsProvider);
    final announcements = announcementsAsync.valueOrNull ?? [];

    final settings = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final address = ref.watch(defaultAddressProvider);
    final lastOrder = ref.watch(lastOrderProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider);
    final closed = !settings.isOpen || settings.holidayMode;
    final firstName = (profile?.name ?? '').trim().split(' ').first;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 14, 20, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context
                            .push(user == null ? '/login' : '/addresses'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName.isEmpty
                                  ? 'Welcome'
                                  : 'Hello, $firstName',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    address == null
                                        ? 'Set delivery location'
                                        : '${address.label} · ${address.area}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: closed
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(closed ? 'Closed' : 'Open',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      GestureDetector(
                        onTap: () => context.push('/admin'),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.admin_panel_settings,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ScaleTap(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: softShadow(0.12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textHint),
                        SizedBox(width: 10),
                        Text('Search pizza, burgers, deals...',
                            style: TextStyle(color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          if (announcements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnnouncementBanner(announcements: announcements),
          ],

          if (closed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoBanner(
                settings.holidayMode && settings.holidayReason.isNotEmpty
                    ? settings.holidayReason
                    : 'We are closed right now. You can browse the menu and order when we open.',
                icon: Icons.access_time,
              ),
            ),

          if (deals.isNotEmpty) ...[
            const SizedBox(height: 20),
            _PromoCarousel(deals: deals, products: popular),
          ],

          const SectionTitle('What are you craving?'),
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final c = categories[i];
                return ScaleTap(
                  onTap: () => context.push('/category/${c.id}'),
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                          ),
                          child: AppImage(
                              imagePath: c.imagePath,
                              width: 64,
                              height: 64,
                              radius: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(c.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionSmall
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
                    .animate(delay: (50 * i).ms)
                    .fadeIn()
                    .slideX(begin: 0.2, end: 0);
              },
            ),
          ),

          if (lastOrder != null) ...[
            const SectionTitle('Order again'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScaleTap(
                onTap: () {
                  final cart = ref.read(cartProvider.notifier);
                  for (final it in lastOrder.items) {
                    cart.add(CartItemModel(
                      productId: it.productId,
                      name: it.name,
                      imagePath: it.imagePath,
                      sizeName: it.sizeName,
                      addonNames: it.addonNames,
                      quantity: it.quantity,
                      unitPrice: it.unitPrice,
                    ));
                  }
                  Helpers.success(
                      context, 'Your last order is back in the cart');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: softShadow(),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.replay,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastOrder.items
                                  .map((e) =>
                                      '${e.quantity}x ${e.name}')
                                  .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelBold,
                            ),
                            Text(Formatters.price(lastOrder.total),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_shopping_cart,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          ],

          if (popular.isNotEmpty) ...[
            SectionTitle('Popular right now',
                action: 'See all',
                onAction: () =>
                    ref.read(navIndexProvider.notifier).state = 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < popular.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: FoodCard(
                              product: popular[i],
                              heroTag: 'home_${popular[i].id}')
                          .animate(delay: (70 * i).ms)
                          .fadeIn()
                          .slideX(begin: 0.15, end: 0),
                    ),
                ],
              ),
            ),
          ],

          if (deals.isNotEmpty) ...[
            const SectionTitle('Value deals'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in deals)
                    DealCard(
                        deal: d,
                        onTap: () => showDealSheet(context, ref, d)),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: AppButton(
              text: 'Browse full menu',
              icon: Icons.restaurant_menu,
              onPressed: () =>
                  ref.read(navIndexProvider.notifier).state = 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ANNOUNCEMENT BANNER ====================
class _AnnouncementBanner extends StatefulWidget {
  final List<Map<String, dynamic>> announcements;
  const _AnnouncementBanner({required this.announcements});

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) return const SizedBox.shrink();

    final text = widget.announcements
        .map((a) => '📢 ${a['title'] ?? ''}: ${a['message'] ?? ''}')
        .join('   •   ');

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout();
                final textWidth = textPainter.width;
                final startX = constraints.maxWidth;
                final endX = -textWidth;
                final x =
                    startX + (endX - startX) * _controller.value;

                return Transform.translate(
                  offset: Offset(x, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ==================== PROMO CAROUSEL ====================
class _PromoCarousel extends StatefulWidget {
  final List<DealModel> deals;
  final List<ProductModel> products;
  const _PromoCarousel({required this.deals, required this.products});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  static const _gradients = [
    [Color(0xFFE63946), Color(0xFFC1121F)],
    [Color(0xFF2B2B2B), Color(0xFF0F0F0F)],
    [Color(0xFFFF9800), Color(0xFFE5700A)],
  ];

  int get _count => widget.deals.length > 5 ? 5 : widget.deals.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || _count < 2) return;
      final next = (_page + 1) % _count;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Column(
        children: [
          SizedBox(
            height: 178,
            child: PageView.builder(
              controller: _controller,
              itemCount: _count,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final d = widget.deals[i];
                final colors = _gradients[i % _gradients.length];
                final img = d.imagePath;
                return ScaleTap(
                  onTap: () => showDealSheet(context, ref, d),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -24,
                          top: 14,
                          bottom: 14,
                          child: ClipOval(
                            child: AppImage(
                                imagePath: img,
                                width: 150,
                                height: 150,
                                radius: 0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('SPECIAL OFFER',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black)),
                              ),
                              const SizedBox(height: 8),
                              Text(d.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 180,
                                child: Text(d.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ),
                              const SizedBox(height: 8),
                              Text(Formatters.price(d.price),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        i == _page ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== MENU ====================
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    if (categories.isEmpty) {
      return const Scaffold(
        body: AppEmpty(
          title: 'No categories yet',
          message: 'Menu is being updated',
          icon: Icons.restaurant_menu,
        ),
      );
    }

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
          actions: [
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push('/search')),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final c in categories) Tab(text: c.name)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final c in categories) _CategoryList(categoryId: c.id),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final String categoryId;
  const _CategoryList({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsByCategoryProvider(categoryId));
    if (products.isEmpty) {
      return const AppEmpty(
          title: 'Nothing here yet',
          message: 'New items are coming soon',
          icon: Icons.restaurant_menu);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductTile(
        product: products[i],
        heroTag: 'menu_${products[i].id}',
        index: i,
      ),
    );
  }
}

class CategoryProductsScreen extends ConsumerWidget {
  final String categoryId;
  const CategoryProductsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsByCategoryProvider(categoryId));
    final cats = ref.watch(categoriesProvider);
    final name =
        cats.where((c) => c.id == categoryId).map((c) => c.name).firstOrNull ??
            'Menu';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Stack(
        children: [
          products.isEmpty
              ? const AppEmpty(
                  title: 'Nothing here yet', icon: Icons.restaurant_menu)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductTile(
                    product: products[i],
                    heroTag: 'cat_${products[i].id}',
                    index: i,
                  ),
                ),
          const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: CartBar())),
        ],
      ),
    );
  }
}

// ==================== SEARCH ====================
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  static const _suggestions = [
    'Pizza',
    'Burger',
    'Wings',
    'Fries',
    'Pasta',
    'Shawarma',
    'Sandwich',
    'Wrap'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(searchQueryProvider.notifier).state = '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _set(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    ref.read(searchQueryProvider.notifier).state = q;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final recents = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
          onSubmitted: (v) =>
              ref.read(recentSearchesProvider.notifier).add(v),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search pizza, burgers, deals...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.close), onPressed: () => _set('')),
        ],
      ),
      body: query.trim().isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (recents.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Recent searches',
                              style: AppTextStyles.headingSmall)),
                      TextButton(
                          onPressed: () => ref
                              .read(recentSearchesProvider.notifier)
                              .clear(),
                          child: const Text('Clear')),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in recents)
                        ActionChip(
                            avatar: const Icon(Icons.history, size: 16),
                            label: Text(r),
                            onPressed: () => _set(r)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                const Text('Popular searches',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                          label: Text(s), onPressed: () => _set(s)),
                  ],
                ),
              ],
            )
          : results.isEmpty
              ? const AppEmpty(
                  title: 'No results',
                  message: 'Try a different word',
                  icon: Icons.search_off)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (_, i) => ProductTile(
                    product: results[i],
                    heroTag: 'search_${results[i].id}',
                    index: i,
                  ),
                ),
    );
  }
}

// ==================== PRODUCT DETAIL ====================
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTag;
  const ProductDetailScreen(
      {super.key, required this.productId, this.heroTag});
  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _sizeIndex = 0;
  final Set<int> _addons = {};
  int _qty = 1;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double _unitPrice(ProductModel p) {
    final base = p.sizes.isEmpty ? p.basePrice : p.sizes[_sizeIndex].price;
    final extra = _addons.fold(0.0, (s, i) => s + p.addons[i].price);
    return base + extra;
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(productByIdProvider(widget.productId));
    if (p == null) {
      return Scaffold(
          appBar: AppBar(), body: const AppEmpty(title: 'Item not found'));
    }
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? <String>{};
    final isFav = favs.contains(p.id);
    final unit = _unitPrice(p);
    final related = ref
        .watch(productsByCategoryProvider(p.categoryId))
        .where((e) => e.id != p.id)
        .take(6)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag ?? 'food_${p.id}',
                child: AppImage(imagePath: p.imagePath),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white),
                  onPressed: () async {
                    final uid = AuthService.uid;
                    if (uid == null) {
                      Helpers.snack(context, 'Log in to save favorites');
                      return;
                    }
                    await FirestoreService.toggleFavorite(uid, p.id);
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child:
                              Text(p.name, style: AppTextStyles.heading)),
                      if (p.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('POPULAR',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.description,
                      style: AppTextStyles.body.copyWith(height: 1.5)),
                  if (!p.isAvailable) ...[
                    const SizedBox(height: 14),
                    const InfoBanner('This item is sold out right now.',
                        color: AppColors.error, icon: Icons.block),
                  ],
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Choose size',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 10),
                    for (var i = 0; i < p.sizes.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _sizeIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _sizeIndex == i
                                ? AppColors.primary
                                    .withValues(alpha: 0.08)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _sizeIndex == i
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _sizeIndex == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _sizeIndex == i
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(p.sizes[i].name,
                                      style: AppTextStyles.labelBold)),
                              Text(Formatters.price(p.sizes[i].price),
                                  style: AppTextStyles.labelBold),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (p.addons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Add extras',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 6),
                    for (var i = 0; i < p.addons.length; i++)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        value: _addons.contains(i),
                        onChanged: (v) => setState(() {
                          v == true ? _addons.add(i) : _addons.remove(i);
                        }),
                        title: Text(p.addons[i].name),
                        secondary: Text(
                            '+ ${Formatters.price(p.addons[i].price)}'),
                      ),
                  ],
                  const SizedBox(height: 18),
                  const Text('Special instructions',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _note,
                    hint: 'e.g. no onions, extra spicy',
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  if (related.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('You may also like',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final r in related)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FoodCard(
                                  product: r,
                                  heroTag: 'rel_${r.id}',
                                  width: 150),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: softShadow(0.12),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              QuantityButton(
                  icon: Icons.remove,
                  onTap: () =>
                      setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
              SizedBox(
                width: 44,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Text('$_qty',
                      key: ValueKey(_qty),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSmall),
                ),
              ),
              QuantityButton(
                  icon: Icons.add, onTap: () => setState(() => _qty++)),
              const SizedBox(width: 14),
              Expanded(
                child: AppButton(
                  text: 'Add  ·  ${Formatters.price(unit * _qty)}',
                  onPressed: p.isAvailable
                      ? () {
                          ref.read(cartProvider.notifier).add(
                                CartItemModel(
                                  productId: p.id,
                                  name: p.name,
                                  imagePath: p.imagePath,
                                  sizeName: p.sizes.isEmpty
                                      ? null
                                      : p.sizes[_sizeIndex].name,
                                  addonNames: _addons
                                      .map((i) => p.addons[i].name)
                                      .toList(),
                                  quantity: _qty,
                                  unitPrice: unit,
                                  instruction: _note.text.trim().isEmpty
                                      ? null
                                      : _note.text.trim(),
                                ),
                              );
                          Helpers.success(
                              context, '${p.name} added to cart');
                          context.pop();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}