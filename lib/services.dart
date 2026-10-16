import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';
import 'models.dart';

// ==================== VALIDATORS ====================
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Invalid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Min 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 3) return 'Min 3 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^(\+92|0)?3[0-9]{9}$').hasMatch(cleaned)) {
      return 'Invalid Pakistani number';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    return null;
  }
}

// ==================== PASSWORD STRENGTH ====================
class PasswordStrength {
  PasswordStrength._();

  static double calculate(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;
    return strength > 1 ? 1 : strength;
  }

  static String label(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Medium';
    if (strength < 0.8) return 'Strong';
    return 'Very Strong';
  }

  static Color color(double strength) {
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.6) return AppColors.warning;
    if (strength < 0.8) return AppColors.info;
    return AppColors.success;
  }
}

// ==================== FORMATTERS ====================
class Formatters {
  Formatters._();

  static String price(num amount) =>
      'Rs ${NumberFormat('#,##0', 'en_PK').format(amount)}';

  static String date(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);
  static String time(DateTime dt) => DateFormat('hh:mm a').format(dt);
  static String dateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? "" : "s"} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w week${w == 1 ? "" : "s"} ago';
    }
    if (diff.inDays < 365) {
      final m = (diff.inDays / 30).floor();
      return '$m month${m == 1 ? "" : "s"} ago';
    }
    final y = (diff.inDays / 365).floor();
    return '$y year${y == 1 ? "" : "s"} ago';
  }

  static String orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return AppColors.statusPlaced;
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'preparing':
        return AppColors.statusPreparing;
      case 'ready':
        return AppColors.statusReady;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ==================== HELPERS ====================
class Helpers {
  Helpers._();

  static void snack(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bg = AppColors.textPrimary;
    IconData? icon;

    if (isError) {
      bg = AppColors.error;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      bg = AppColors.success;
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        margin: const EdgeInsets.all(AppSizes.p16),
      ),
    );
  }

  static void success(BuildContext context, String msg) =>
      snack(context, msg, isSuccess: true);

  static void error(BuildContext context, String msg) =>
      snack(context, msg, isError: true);

  static Future<void> whatsapp(String phone, {String? message}) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    final formatted = cleaned.startsWith('92')
        ? cleaned
        : cleaned.startsWith('0')
            ? '92${cleaned.substring(1)}'
            : '92$cleaned';
    final url = message != null
        ? 'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}'
        : 'https://wa.me/$formatted';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> openMap(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ==================== AUTH SERVICE ====================
class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email.trim(),
      'phone': phone,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', false);
    return cred;
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', false);
    return cred;
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', false);
    await _auth.signOut();
  }

  static Future<UserModel?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, user.uid);
  }

  static bool isAdminEmail(String? email) {
    return email?.toLowerCase() == AppConfig.adminEmail.toLowerCase();
  }

  static Future<void> updateProfile({String? name, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = <String, dynamic>{};
    if (name != null) {
      data['name'] = name;
      await user.updateDisplayName(name);
    }
    if (phone != null) data['phone'] = phone;
    await _db.collection('users').doc(user.uid).update(data);
  }

  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).delete();
    await user.delete();
  }
}

// ==================== FIRESTORE SERVICE ====================
class FirestoreService {
  FirestoreService._();

  static final _db = FirebaseFirestore.instance;

  // ==================== ORDERS ====================
  static Future<String> placeOrder(OrderModel order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  static Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({'status': 'cancelled'});
  }

  static Future<void> deleteOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  // ==================== PRODUCTS ====================
  static Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toMap());
  }

  static Future<void> updateProduct(String id, ProductModel product) async {
    await _db.collection('products').doc(id).update(product.toMap());
  }

  static Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ==================== CATEGORIES ====================
  static Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').add(category.toMap());
  }

  static Future<void> updateCategory(String id, CategoryModel category) async {
    await _db.collection('categories').doc(id).update(category.toMap());
  }

  static Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // ==================== DEALS ====================
  static Future<void> addDeal(DealModel deal) async {
    await _db.collection('deals').add(deal.toMap());
  }

  static Future<void> updateDeal(String id, DealModel deal) async {
    await _db.collection('deals').doc(id).update(deal.toMap());
  }

  static Future<void> deleteDeal(String id) async {
    await _db.collection('deals').doc(id).delete();
  }

  // ==================== BANNERS ====================
  static Future<void> addBanner(BannerModel banner) async {
    await _db.collection('banners').add(banner.toMap());
  }

  static Future<void> updateBanner(String id, BannerModel banner) async {
    await _db.collection('banners').doc(id).update(banner.toMap());
  }

  static Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  // ==================== PROMOS ====================
  static Future<void> addPromo(PromoModel promo) async {
    await _db.collection('promoCodes').add(promo.toMap());
  }

  static Future<void> updatePromo(String id, PromoModel promo) async {
    await _db.collection('promoCodes').doc(id).update(promo.toMap());
  }

  static Future<void> deletePromo(String id) async {
    await _db.collection('promoCodes').doc(id).delete();
  }

  static Future<PromoModel?> validatePromo(String code) async {
    final snap = await _db
        .collection('promoCodes')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final promo = PromoModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    if (promo.expiry != null && promo.expiry!.isBefore(DateTime.now())) {
      return null;
    }
    return promo;
  }

  // ==================== ADDRESSES ====================
  static Future<String> addAddress(String uid, AddressModel address) async {
    final ref = await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .add(address.toMap());
    return ref.id;
  }

  static Future<void> updateAddress(
      String uid, String addressId, AddressModel address) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .update(address.toMap());
  }

  static Future<void> deleteAddress(String uid, String addressId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  static Future<void> setDefaultAddress(String uid, String addressId) async {
    final ref = _db.collection('users').doc(uid).collection('addresses');
    final all = await ref.get();
    final batch = _db.batch();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  // ==================== FAVORITES ====================
  static Future<void> toggleFavorite(String uid, String productId) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  // ==================== REVIEWS ====================
  static Future<void> addReview(ReviewModel review) async {
    await _db.collection('reviews').add(review.toMap());
  }

  static Future<void> deleteReview(String id) async {
    await _db.collection('reviews').doc(id).delete();
  }

  // ==================== SETTINGS ====================
  static Future<void> updateSettings(SettingsModel settings) async {
    await _db.collection('settings').doc('app').set(settings.toMap());
  }

  // ==================== NOTIFICATIONS ====================
  static Future<void> sendNotification({
    required String title,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'title': title,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'to': 'all',
    });
  }

  // ==================== USERS (Admin) ====================
  static Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ==================== SEARCH ====================
  static Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    final snap = await _db
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .get();
    final lower = query.toLowerCase();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) => p.name.toLowerCase().contains(lower))
        .toList();
  }
}

// ==================== LOCATION SERVICE ====================
class LocationService {
  LocationService._();

  static Future<bool> isServiceEnabled() async =>
      await Geolocator.isLocationServiceEnabled();

  static Future<LocationPermission> checkPermission() async =>
      await Geolocator.checkPermission();

  static Future<LocationPermission> requestPermission() async =>
      await Geolocator.requestPermission();

  static Future<bool> ensurePermission() async {
    final enabled = await isServiceEnabled();
    if (!enabled) return false;

    var perm = await checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await requestPermission();
      if (perm == LocationPermission.denied) return false;
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      if (!await ensurePermission()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static double distanceFromRestaurant(double lat, double lng) {
    return Geolocator.distanceBetween(
          AppConfig.restaurantLat,
          AppConfig.restaurantLng,
          lat,
          lng,
        ) /
        1000;
  }

  static Future<void> openSettings() async =>
      await Geolocator.openAppSettings();

  static Future<void> openLocationSettings() async =>
      await Geolocator.openLocationSettings();
}

// ==================== NOTIFICATION SERVICE ====================
class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken(vapidKey: AppConfig.vapidKey);
    if (kDebugMode) print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) print('Foreground: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) print('Tapped: ${message.data}');
    });
  }

  static Future<String?> getToken() async =>
      await _messaging.getToken(vapidKey: AppConfig.vapidKey);

  static Future<void> subscribe(String topic) async =>
      await _messaging.subscribeToTopic(topic);

  static Future<void> unsubscribe(String topic) async =>
      await _messaging.unsubscribeFromTopic(topic);
}