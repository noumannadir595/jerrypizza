import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_data.dart';
import 'models.dart';
import 'services.dart';

FirebaseFirestore get _db => FirebaseFirestore.instance;

// ==================== UI STATE ====================
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('dark') ?? false) state = ThemeMode.dark;
    } catch (_) {}
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark', dark);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super(const []) {
    _load();
  }

  static const _key = 'recent_searches';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getStringList(_key) ?? [];
    } catch (_) {}
  }

  Future<void> add(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    state = [t, ...state.where((e) => e.toLowerCase() != t.toLowerCase())]
        .take(8)
        .toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state);
    } catch (_) {}
  }

  Future<void> clear() async {
    state = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
        (ref) => RecentSearchesNotifier());

final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool ok(List<ConnectivityResult> r) => !r.contains(ConnectivityResult.none);
  yield ok(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(ok);
});

final navIndexProvider = StateProvider<int>((ref) => 0);
final searchQueryProvider = StateProvider<String>((ref) => '');

// ==================== AUTH ====================
final authStateProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return _db.collection('users').doc(user.uid).snapshots().map(
        (d) => d.exists ? UserModel.fromMap(d.data()!, user.uid) : null,
      );
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return AuthService.isAdminEmail(user?.email);
});

// ==================== MENU ====================
final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  final list = MenuData.categories;
  return [
    for (var i = 0; i < list.length; i++)
      CategoryModel(
        id: list[i]['id']!,
        name: list[i]['name']!,
        imagePath: list[i]['imagePath'] ?? '',
        order: i,
      ),
  ];
});

final menuStatusProvider = StreamProvider<Map<String, bool>>((ref) {
  return _db.collection('menuStatus').snapshots().map((s) => {
        for (final d in s.docs)
          d.id: (d.data()['available'] ?? true) == true,
      });
});

final productsProvider = Provider<List<ProductModel>>((ref) {
  final status = ref.watch(menuStatusProvider).valueOrNull ?? const {};
  return MenuData.products.map((m) {
    final map = Map<String, dynamic>.from(m);
    final id = m['id'] as String;
    if (status.containsKey(id)) map['isAvailable'] = status[id];
    return ProductModel.fromMap(map, id);
  }).toList();
});

final dealsProvider = Provider<List<DealModel>>((ref) {
  return MenuData.deals
      .map((m) =>
          DealModel.fromMap(Map<String, dynamic>.from(m), m['id'] as String))
      .toList();
});

final popularProductsProvider = Provider<List<ProductModel>>(
  (ref) => ref.watch(productsProvider).where((p) => p.isPopular).toList(),
);

final productsByCategoryProvider =
    Provider.family<List<ProductModel>, String>((ref, categoryId) {
  return ref
      .watch(productsProvider)
      .where((p) => p.categoryId == categoryId)
      .toList();
});

final productByIdProvider =
    Provider.family<ProductModel?, String>((ref, id) {
  for (final p in ref.watch(productsProvider)) {
    if (p.id == id) return p;
  }
  return null;
});

final lastOrderProvider = Provider<OrderModel?>((ref) {
  final list = ref.watch(myOrdersProvider).valueOrNull ?? [];
  for (final o in list) {
    if (o.status != 'cancelled') return o;
  }
  return null;
});

final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final list = ref.watch(addressesProvider).valueOrNull ?? [];
  if (list.isEmpty) return null;
  return list.where((a) => a.isDefault).firstOrNull ?? list.first;
});

final searchResultsProvider = Provider<List<ProductModel>>((ref) {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (q.isEmpty) return [];
  return ref
      .watch(productsProvider)
      .where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q))
      .toList();
});

// ==================== SETTINGS ====================
final settingsProvider = StreamProvider<SettingsModel>((ref) {
  return _db.collection('settings').doc('app').snapshots().map(
        (d) =>
            d.exists ? SettingsModel.fromMap(d.data()!) : SettingsModel(),
      );
});

// ==================== ANNOUNCEMENTS ====================
final announcementsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _db.collection('announcements').limit(10).snapshots().map((s) {
    final list = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    list.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list.take(5).toList();
  });
});

// ==================== CART ====================
CartItemModel _cartFromMap(Map<String, dynamic> m) => CartItemModel(
      productId: m['productId'] ?? '',
      name: m['name'] ?? '',
      imagePath: m['imagePath'] ?? '',
      sizeName: m['sizeName'],
      addonNames:
          (m['addonNames'] as List?)?.map((e) => e.toString()).toList() ?? [],
      quantity: (m['quantity'] ?? 1) as int,
      unitPrice: (m['unitPrice'] ?? 0).toDouble(),
      instruction: m['instruction'],
    );

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super(const []) {
    _load();
  }

  static const _key = 'cart_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => _cartFromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (state.isEmpty) state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((e) => e.toMap()).toList()));
    } catch (_) {}
  }

  void add(CartItemModel item) {
    final i = state.indexWhere((e) => e.key == item.key);
    if (i >= 0) {
      final list = [...state];
      list[i] = list[i].copyWith(quantity: list[i].quantity + item.quantity);
      state = list;
    } else {
      state = [...state, item];
    }
    _save();
  }

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) return remove(key);
    state = [
      for (final e in state) e.key == key ? e.copyWith(quantity: quantity) : e,
    ];
    _save();
  }

  void remove(String key) {
    state = state.where((e) => e.key != key).toList();
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>(
        (ref) => CartNotifier());

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (s, e) => s + e.quantity),
);

final cartSubtotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider).fold(0.0, (s, e) => s + e.lineTotal),
);

// ==================== ORDERS ====================
final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return _db
      .collection('orders')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((s) {
    final list =
        s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final orderProvider =
    StreamProvider.family<OrderModel?, String>((ref, id) {
  return _db.collection('orders').doc(id).snapshots().map(
        (d) => d.exists ? OrderModel.fromMap(d.data()!, d.id) : null,
      );
});

// ==================== ADDRESSES & FAVORITES ====================
final addressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return _db
      .collection('users')
      .doc(user.uid)
      .collection('addresses')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => AddressModel.fromMap(d.data(), d.id)).toList());
});

final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(<String>{});
  return _db
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
});

final favoriteProductsProvider = Provider<List<ProductModel>>((ref) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? <String>{};
  return ref.watch(productsProvider).where((p) => ids.contains(p.id)).toList();
});

// ==================== NOTIFICATIONS ====================
final notificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _db.collection('notifications').limit(50).snapshots().map((s) {
    final list = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    list.sort((a, b) {
      final aTime = (a['sentAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = (b['sentAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  });
});

// ==================== ADMIN ====================
final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return _db.collection('orders').limit(200).snapshots().map((s) {
    final list =
        s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final promosProvider = StreamProvider<List<PromoModel>>((ref) {
  return _db
      .collection('promoCodes')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => PromoModel.fromMap(d.data(), d.id)).toList());
});

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return _db
      .collection('users')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
});

// ==================== ADMIN VIEWED ORDERS ====================
class AdminViewedOrdersNotifier extends StateNotifier<Set<String>> {
  AdminViewedOrdersNotifier() : super(<String>{}) {
    _load();
  }

  static const _key = 'admin_viewed_orders';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> markViewed(String orderId) async {
    state = {...state, orderId};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList());
    } catch (_) {}
  }

  Future<void> markAllViewed(List<String> ids) async {
    state = {...state, ...ids};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList());
    } catch (_) {}
  }
}

final adminViewedOrdersProvider =
    StateNotifierProvider<AdminViewedOrdersNotifier, Set<String>>(
        (ref) => AdminViewedOrdersNotifier());

final unreadOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(allOrdersProvider).valueOrNull ?? [];
  final viewed = ref.watch(adminViewedOrdersProvider);
  return orders
      .where((o) => o.status != 'delivered' && o.status != 'cancelled')
      .where((o) => !viewed.contains(o.id))
      .length;
});