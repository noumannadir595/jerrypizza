import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';
import '../models.dart';
import '../providers.dart';
import '../services.dart';
import '../widgets.dart';

// ==================== CART ====================
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final products = ref.watch(productsProvider);

    final inCart = items.map((e) => e.productId).toSet();
    final extras = products
        .where((p) =>
            (p.categoryId == 'drinks' || p.categoryId == 'fries') &&
            p.isAvailable &&
            !inCart.contains(p.id))
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await AppDialog.confirm(context,
                    title: 'Clear cart?',
                    message: 'All items will be removed from your cart.',
                    confirmText: 'Clear',
                    isDestructive: true);
                if (ok) ref.read(cartProvider.notifier).clear();
              },
              child:
                  const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: items.isEmpty
          ? AppEmpty(
              title: 'Your cart is empty',
              message: 'Looks like you have not added anything yet',
              icon: Icons.shopping_bag_outlined,
              buttonText: 'Browse menu',
              onButtonPressed: () =>
                  ref.read(navIndexProvider.notifier).state = 1,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _CartTile(item: items[i])
                            .animate(delay: (40 * i).ms)
                            .fadeIn()
                            .slideY(begin: 0.08, end: 0),
                      if (extras.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Add something extra',
                            style: AppTextStyles.headingSmall),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final p in extras)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: FoodCard(
                                      product: p,
                                      heroTag: 'cart_${p.id}',
                                      width: 150),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: softShadow(0.12),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BillRow('Subtotal', Formatters.price(subtotal)),
                        const SizedBox(height: 6),
                        AppButton(
                          text: user == null
                              ? 'Log in to checkout'
                              : 'Proceed to checkout',
                          onPressed: () => context
                              .push(user == null ? '/login' : '/checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  final CartItemModel item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final it = item;
    final notifier = ref.read(cartProvider.notifier);
    return Dismissible(
      key: ValueKey(it.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.error, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => notifier.remove(it.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow(),
        ),
        child: Row(
          children: [
            AppImage(
                imagePath: it.imagePath, width: 72, height: 72, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelBold),
                  if (it.sizeName != null || it.addonNames.isNotEmpty)
                    Text(
                      [if (it.sizeName != null) it.sizeName!, ...it.addonNames]
                          .join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 6),
                  Text(Formatters.price(it.lineTotal),
                      style: AppTextStyles.priceSmall
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            QuantityButton(
                icon: it.quantity == 1 ? Icons.delete_outline : Icons.remove,
                onTap: () => notifier.setQuantity(it.key, it.quantity - 1)),
            SizedBox(
              width: 34,
              child: Text('${it.quantity}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelBold),
            ),
            QuantityButton(
                icon: Icons.add,
                onTap: () => notifier.setQuantity(it.key, it.quantity + 1)),
          ],
        ),
      ),
    );
  }
}

// ==================== CHECKOUT ====================
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _orderType = 'delivery';
  String? _addressId;
  PromoModel? _promo;
  double _tip = 0;
  bool _placing = false;
  bool _checkingPromo = false;
  bool _askedLocation = false;
  final _promoCtrl = TextEditingController();
  final _note = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile?.phone != null && profile!.phone.isNotEmpty) {
        _phoneCtrl.text = profile.phone;
      }
    });
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _note.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  double _discount(double subtotal) {
    final p = _promo;
    if (p == null) return 0;
    double d = p.type == 'percent' ? subtotal * p.value / 100 : p.value;
    if (p.type == 'percent' && p.maxDiscount > 0 && d > p.maxDiscount) {
      d = p.maxDiscount;
    }
    return d > subtotal ? subtotal : d;
  }

  double _calculateFee(
      AddressModel? address, SettingsModel settings, double subtotal) {
    if (address == null || address.lat == 0) return settings.deliveryFee;

    final km = Geolocator.distanceBetween(
          settings.restaurantLat,
          settings.restaurantLng,
          address.lat,
          address.lng,
        ) /
        1000;

    if (km <= AppConfig.freeDeliveryRadiusKm &&
        subtotal >= AppConfig.minOrderAmount) {
      return 0;
    }

    return settings.deliveryFee;
  }

  Future<void> _applyPromo(double subtotal) async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _checkingPromo = true);
    try {
      final promo = await FirestoreService.validatePromo(code);
      if (!mounted) return;
      if (promo == null) {
        Helpers.error(context, 'This promo code is invalid or has expired');
      } else if (subtotal < promo.minOrder) {
        Helpers.error(
            context,
            'This code needs a minimum order of ${Formatters.price(promo.minOrder)}');
      } else {
        setState(() => _promo = promo);
        Helpers.success(context, 'Promo code applied');
      }
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _checkingPromo = false);
    }
  }

  Future<void> _place({
    required List<CartItemModel> cart,
    required AddressModel? address,
    required SettingsModel settings,
    required double subtotal,
    required double fee,
    required double discount,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }
    if (_orderType == 'delivery' && address == null) {
      Helpers.error(context, 'Please choose a delivery location');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty ||
        Validators.phone(_phoneCtrl.text.trim()) != null) {
      Helpers.error(context, 'Please enter a valid phone number');
      return;
    }

    setState(() => _placing = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final instructions = [
        if (_note.text.trim().isNotEmpty) _note.text.trim(),
        for (final c in cart)
          if (c.instruction != null && c.instruction!.isNotEmpty)
            '${c.name}: ${c.instruction}',
      ].join('\n');

      double liveLat = 0;
      double liveLng = 0;
      try {
        final pos = await LocationService.getCurrentLocation();
        if (pos != null) {
          liveLat = pos.latitude;
          liveLng = pos.longitude;
        }
      } catch (_) {}

      final order = OrderModel(
        id: '',
        userId: user.uid,
        userName: profile?.name ?? user.displayName ?? '',
        userPhone: _phoneCtrl.text.trim(),
        items: cart
            .map((c) => OrderItemModel(
                  productId: c.productId,
                  name: c.name,
                  imagePath: c.imagePath,
                  sizeName: c.sizeName,
                  addonNames: c.addonNames,
                  quantity: c.quantity,
                  unitPrice: c.unitPrice,
                ))
            .toList(),
        orderType: _orderType,
        address: _orderType == 'delivery' ? address : null,
        subtotal: subtotal,
        deliveryFee: fee,
        discount: discount,
        tip: _orderType == 'delivery' ? _tip : 0,
        total:
            subtotal + fee + (_orderType == 'delivery' ? _tip : 0) - discount,
        note: instructions.isEmpty ? null : instructions,
        promoCode: _promo?.code,
        createdAt: DateTime.now(),
        liveLat: liveLat,
        liveLng: liveLng,
      );
      await FirestoreService.placeOrder(order);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      Helpers.success(context, 'Order placed successfully!');
      context.go('/home');
    } catch (_) {
      if (mounted) {
        Helpers.error(context, 'Could not place the order. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final settings = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    final addressAsync = ref.watch(addressesProvider);
    final addresses = addressAsync.valueOrNull ?? [];

    if (!_askedLocation &&
        addressAsync.hasValue &&
        addresses.isEmpty &&
        _orderType == 'delivery') {
      _askedLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/location');
      });
    }

    AddressModel? selected;
    if (addresses.isNotEmpty) {
      selected = addresses.where((a) => a.id == _addressId).firstOrNull ??
          addresses.where((a) => a.isDefault).firstOrNull ??
          addresses.first;
    }

    final isDelivery = _orderType == 'delivery';
    final fee =
        !isDelivery ? 0.0 : _calculateFee(selected, settings, subtotal);
    final tip = isDelivery ? _tip : 0.0;
    final discount = _discount(subtotal);
    final total = subtotal + fee + tip - discount;
    final closed = !settings.isOpen || settings.holidayMode;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const AppEmpty(title: 'Your cart is empty'),
      );
    }

    Widget card(Widget child) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: softShadow(),
          ),
          child: child,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (closed)
            const InfoBanner(
                'The restaurant is closed right now, so orders are paused.',
                color: AppColors.error,
                icon: Icons.block),

          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order type', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'delivery',
                        label: Text('Delivery'),
                        icon: Icon(Icons.delivery_dining)),
                    ButtonSegment(
                        value: 'pickup',
                        label: Text('Pickup'),
                        icon: Icon(Icons.storefront)),
                  ],
                  selected: {_orderType},
                  onSelectionChanged: (s) =>
                      setState(() => _orderType = s.first),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    isDelivery
                        ? 'Estimated delivery: 30 - 45 min'
                        : 'Ready for pickup in about 20 min',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          )),

          if (isDelivery)
            card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                        child: Text('Delivery location',
                            style: AppTextStyles.headingSmall)),
                    TextButton.icon(
                      onPressed: () => context.push('/location'),
                      icon: const Icon(Icons.add_location_alt_outlined,
                          size: 18),
                      label: const Text('Add new'),
                    ),
                  ],
                ),
                if (addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AppButton(
                      text: 'Pick location on map',
                      icon: Icons.my_location,
                      onPressed: () => context.push('/location'),
                    ),
                  ),
                for (final a in addresses)
                  GestureDetector(
                    onTap: () => setState(() => _addressId = a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected?.id == a.id
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : null,
                        border: Border.all(
                          color: selected?.id == a.id
                              ? AppColors.primary
                              : AppColors.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            a.label == 'Work'
                                ? Icons.work_outline
                                : a.label == 'Home'
                                    ? Icons.home_outlined
                                    : Icons.place_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.label, style: AppTextStyles.labelBold),
                                Text(a.fullAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption),
                                Text(a.phone, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          if (selected?.id == a.id)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ))
          else
            card(Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup from',
                          style: AppTextStyles.labelBold),
                      Text(
                        AppStrings.pickupAddress,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            )),

          card(AppTextField(
            label: 'Your phone number *',
            hint: '03xx xxxxxxx',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: Validators.phone,
          )),

          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Promo code', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _promoCtrl,
                      hint: 'Enter code',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 104,
                    child: AppButton(
                      text: _promo == null ? 'Apply' : 'Applied',
                      isLoading: _checkingPromo,
                      onPressed: () => _applyPromo(subtotal),
                    ),
                  ),
                ],
              ),
            ],
          )),

          if (isDelivery)
            card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tip your rider',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Text('100% of the tip goes to the rider',
                    style: AppTextStyles.caption),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in [0.0, 30.0, 50.0, 100.0])
                      ChoiceChip(
                        label:
                            Text(t == 0 ? 'No tip' : Formatters.price(t)),
                        selected: _tip == t,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.18),
                        onSelected: (_) => setState(() => _tip = t),
                      ),
                  ],
                ),
              ],
            )),

          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primary, width: 1.5),
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(child: Text('Cash on Delivery')),
                    Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          )),

          card(AppTextField(
            label: 'Order note (optional)',
            controller: _note,
            maxLines: 2,
            textInputAction: TextInputAction.done,
          )),

          card(Column(
            children: [
              BillRow('Subtotal', Formatters.price(subtotal)),
              if (isDelivery)
                BillRow(
                    'Delivery fee',
                    fee == 0 ? 'Free' : Formatters.price(fee),
                    valueColor: fee == 0 ? AppColors.success : null),
              if (tip > 0) BillRow('Rider tip', Formatters.price(tip)),
              if (discount > 0)
                BillRow('Discount', '- ${Formatters.price(discount)}',
                    valueColor: AppColors.success),
              const Divider(height: 24),
              BillRow('Total', Formatters.price(total), bold: true),
            ],
          )),
          const SizedBox(height: 4),
          AppButton(
            text: 'Place order  ·  ${Formatters.price(total)}',
            isLoading: _placing,
            onPressed: closed
                ? null
                : () => _place(
                      cart: cart,
                      address: selected,
                      settings: settings,
                      subtotal: subtotal,
                      fee: fee,
                      discount: discount,
                    ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==================== ORDER SUCCESS ====================
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 120),
              const SizedBox(height: 28),
              const Text('Order placed!',
                  style: AppTextStyles.display,
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              AppButton(
                  text: 'Back to home',
                  onPressed: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ORDER HISTORY ====================
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final orders = ref.watch(myOrdersProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: AppEmpty(
          title: 'Log in to see your orders',
          message: 'Track your orders and reorder your favorites',
          icon: Icons.lock_outline,
          buttonText: 'Log in',
          onButtonPressed: () => context.push('/login'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Active'), Tab(text: 'Past')],
          ),
        ),
        body: orders.when(
          loading: () => const AppLoading(),
          error: (e, _) =>
              AppError(onRetry: () => ref.invalidate(myOrdersProvider)),
          data: (list) {
            final active = list
                .where((o) =>
                    o.status != 'delivered' && o.status != 'cancelled')
                .toList();
            final past = list
                .where((o) =>
                    o.status == 'delivered' || o.status == 'cancelled')
                .toList();
            return TabBarView(children: [
              _OrderList(
                  orders: active,
                  emptyTitle: 'No active orders',
                  emptyMessage: 'Orders you place will show up here'),
              _OrderList(
                  orders: past,
                  emptyTitle: 'No past orders',
                  emptyMessage: 'Delivered and cancelled orders appear here'),
            ]);
          },
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final List<OrderModel> orders;
  final String emptyTitle;
  final String emptyMessage;
  const _OrderList(
      {required this.orders,
      required this.emptyTitle,
      required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return AppEmpty(
          title: emptyTitle,
          message: emptyMessage,
          icon: Icons.receipt_long_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return ScaleTap(
          onTap: () => context.push('/order/${o.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Order # ${shortOrderId(o.id)}',
                          style: AppTextStyles.labelBold),
                    ),
                    StatusBadge(
                      status: Formatters.orderStatus(o.status),
                      color: Formatters.orderStatusColor(o.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  o.items
                      .map((e) => '${e.quantity}x ${e.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(Formatters.dateTime(o.createdAt),
                          style: AppTextStyles.caption),
                    ),
                    Text(Formatters.price(o.total),
                        style: AppTextStyles.priceSmall
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push('/order/${o.id}'),
                        child: Text(
                            o.status == 'delivered' ||
                                    o.status == 'cancelled'
                                ? 'Details'
                                : 'Track'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final cart = ref.read(cartProvider.notifier);
                          for (final it in o.items) {
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
                          ref.read(navIndexProvider.notifier).state = 2;
                          Helpers.success(
                              context, 'Items added to your cart');
                        },
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Reorder'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate(delay: (40 * (i > 8 ? 8 : i)).ms)
            .fadeIn()
            .slideY(begin: 0.08, end: 0);
      },
    );
  }
}

// ==================== ORDER TRACKING ====================
class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    ('placed', 'Order placed', 'We have received your order',
        Icons.receipt_long),
    ('confirmed', 'Confirmed', 'The restaurant accepted your order',
        Icons.thumb_up_alt_outlined),
    ('preparing', 'Preparing', 'Your food is being freshly made',
        Icons.soup_kitchen_outlined),
    ('ready', 'Ready', 'Out for delivery or ready for pickup',
        Icons.delivery_dining),
    ('delivered', 'Delivered', 'Enjoy your meal!',
        Icons.celebration_outlined),
  ];

  Future<void> _rate(BuildContext context, OrderModel o) async {
    double rating = 5;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Rate your order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setS(() => rating = i.toDouble()),
                      icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                          size: 32),
                    ),
                ],
              ),
              TextField(
                controller: ctrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Comment (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await FirestoreService.addReview(ReviewModel(
        id: '',
        orderId: o.id,
        userId: o.userId,
        userName: o.userName,
        rating: rating,
        comment: ctrl.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (context.mounted) {
        Helpers.success(context, 'Thanks for your feedback!');
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderProvider(orderId));
    final settings = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();

    return Scaffold(
      appBar: AppBar(
        title: Text('Order # ${shortOrderId(orderId)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) =>
            AppError(onRetry: () => ref.invalidate(orderProvider(orderId))),
        data: (o) {
          if (o == null) return const AppEmpty(title: 'Order not found');
          final cancelled = o.status == 'cancelled';
          final stepIndex = _steps.indexWhere((s) => s.$1 == o.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: cancelled
                      ? const LinearGradient(
                          colors: [Color(0xFF616161), Color(0xFF424242)])
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                      child: Icon(
                        cancelled
                            ? Icons.cancel_outlined
                            : _steps[stepIndex < 0 ? 0 : stepIndex].$4,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Formatters.orderStatus(o.status),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            cancelled
                                ? 'This order was cancelled'
                                : o.status == 'delivered'
                                    ? 'Delivered successfully'
                                    : 'Estimated time: 30 - 45 min',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
              const SizedBox(height: 16),
              if (!cancelled)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: softShadow(),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        _TimelineRow(
                          title: _steps[i].$2,
                          subtitle: _steps[i].$3,
                          done: i < stepIndex || o.status == 'delivered',
                          current:
                              i == stepIndex && o.status != 'delivered',
                          isLast: i == _steps.length - 1,
                        )
                            .animate(delay: (80 * i).ms)
                            .fadeIn()
                            .slideX(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: softShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order summary',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    for (final it in o.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            AppImage(
                                imagePath: it.imagePath,
                                width: 44,
                                height: 44,
                                radius: 10),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('${it.quantity} x ${it.name}',
                                      style: AppTextStyles.label),
                                  if (it.sizeName != null ||
                                      it.addonNames.isNotEmpty)
                                    Text(
                                      [
                                        if (it.sizeName != null)
                                          it.sizeName!,
                                        ...it.addonNames
                                      ].join(' • '),
                                      style: AppTextStyles.captionSmall,
                                    ),
                                ],
                              ),
                            ),
                            Text(Formatters.price(it.lineTotal),
                                style: AppTextStyles.label),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    BillRow('Subtotal', Formatters.price(o.subtotal)),
                    if (o.orderType == 'delivery')
                      BillRow(
                          'Delivery fee',
                          o.deliveryFee == 0
                              ? 'Free'
                              : Formatters.price(o.deliveryFee)),
                    if (o.tip > 0)
                      BillRow('Rider tip', Formatters.price(o.tip)),
                    if (o.discount > 0)
                      BillRow('Discount',
                          '- ${Formatters.price(o.discount)}',
                          valueColor: AppColors.success),
                    const Divider(height: 24),
                    BillRow('Total', Formatters.price(o.total),
                        bold: true),
                    const SizedBox(height: 10),
                    Text('Payment: Cash on Delivery',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: softShadow(),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(
                          o.orderType == 'delivery'
                              ? Icons.location_on
                              : Icons.storefront,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              o.orderType == 'delivery'
                                  ? 'Delivering to'
                                  : 'Pickup from',
                              style: AppTextStyles.labelBold),
                          Text(
                              o.orderType == 'delivery'
                                  ? (o.address?.fullAddress ?? '')
                                  : AppStrings.pickupAddress,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (o.orderType == 'delivery' &&
                        o.address != null &&
                        o.address!.lat != 0)
                      IconButton(
                        icon: const Icon(Icons.map_outlined,
                            color: AppColors.primary),
                        onPressed: () =>
                            Helpers.openMap(o.address!.lat, o.address!.lng),
                      ),
                  ],
                ),
              ),
              if (o.note != null) ...[
                const SizedBox(height: 12),
                InfoBanner('Note: ${o.note}',
                    color: AppColors.info,
                    icon: Icons.sticky_note_2_outlined),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Helpers.call(settings.contactNumber),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Helpers.whatsapp(
                          settings.whatsappNumber,
                          message:
                              'Hi, about my order # ${shortOrderId(o.id)}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (o.status == 'delivered')
                AppButton(
                    text: 'Rate this order',
                    icon: Icons.star_outline,
                    onPressed: () => _rate(context, o)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final bool isLast;
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = done || current ? AppColors.success : AppColors.textHint;
    Widget dot = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.success : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : current
              ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                  ),
                )
              : null,
    );
    if (current) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.9, end: 1.15, duration: 800.ms);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              dot,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.success : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: current || done
                          ? AppTextStyles.labelBold
                          : AppTextStyles.label
                              .copyWith(color: AppColors.textHint)),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}