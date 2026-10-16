import 'package:go_router/go_router.dart';

import 'models.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screens.dart';
import 'screens/location_screens.dart';
import 'screens/order_screens.dart';
import 'screens/profile_screens.dart';
import 'admin.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
    GoRoute(path: '/forgot', builder: (c, s) => const ForgotPasswordScreen()),
    GoRoute(path: '/home', builder: (c, s) => const MainNavScreen()),
    GoRoute(
      path: '/category/:id',
      builder: (c, s) =>
          CategoryProductsScreen(categoryId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (c, s) => ProductDetailScreen(
        productId: s.pathParameters['id']!,
        heroTag: s.extra is String ? s.extra as String : null,
      ),
    ),
    GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
    GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
    GoRoute(
      path: '/success/:id',
      builder: (c, s) => OrderSuccessScreen(orderId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/order/:id',
      builder: (c, s) =>
          OrderTrackingScreen(orderId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/addresses', builder: (c, s) => const AddressListScreen()),
    GoRoute(
      path: '/address/add',
      builder: (c, s) =>
          LocationPickerScreen(existing: s.extra as AddressModel?),
    ),
    GoRoute(
      path: '/location',
      builder: (c, s) =>
          LocationPickerScreen(existing: s.extra as AddressModel?),
    ),
    GoRoute(path: '/help', builder: (c, s) => const HelpScreen()),
    GoRoute(
      path: '/legal/:type',
      builder: (c, s) => LegalScreen(type: s.pathParameters['type'] ?? 'terms'),
    ),
    GoRoute(path: '/favorites', builder: (c, s) => const FavoritesScreen()),
    GoRoute(path: '/edit-profile', builder: (c, s) => const EditProfileScreen()),
    GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/about', builder: (c, s) => const AboutScreen()),

    // ✅ ADMIN ROUTES (naya)
    GoRoute(path: '/admin-login', builder: (c, s) => const AdminLoginScreen()),
    GoRoute(path: '/admin', builder: (c, s) => const AdminDashboardScreen()),
  ],
);