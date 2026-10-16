import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._();

  static const String adminEmail = 'adminjp@gmail.com';

  static const String vapidKey = 'YOUR_VAPID_KEY_HERE';

  static const double restaurantLat = 30.653329349399;
  static const double restaurantLng = 73.1191797513746;

  static const double freeDeliveryRadiusKm = 1.0;

  static const double maxDeliveryRadiusKm = 5.0;

  static const double minOrderAmount = 1000.0;
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Jerry Pizza & Chicken Karrahi';
  static const String appTagline = 'Family Restaurant';
  static const String noInternet = 'No internet connection';
  static const String somethingWentWrong = 'Something went wrong';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';
  static const String continueAsGuest = 'Continue as Guest';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone';
  static const String resetPassword = 'Reset Password';
  static const String send = 'Send';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String adminPanel = 'Admin Panel';
  static const String loginTitle = 'Welcome Back';
  static const String signupTitle = 'Create Account';
  static const String onboardTitle1 = 'Delicious Pizza';
  static const String onboardDesc1 = 'Freshly baked with love';
  static const String onboardTitle2 = 'Fast Delivery';
  static const String onboardDesc2 = 'Hot food at your doorstep';
  static const String onboardTitle3 = 'Track Order';
  static const String onboardDesc3 = 'Know exactly where your food is';
  static const String pickupAddress =
      'Pick your parcel from Jerry Pizza near Bulbul Hotel';

  static const String appVersion = 'Version 1.0.0';
  static const String developerName = 'Developed by Nouman Nadir';
  static const String developerEmail = 'noumannadir595@gmail.com';
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE63946);
  static const Color accent = Color(0xFFFFC107);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color shimmer = Color(0xFFF0F0F0);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color statusPlaced = Color(0xFF1976D2);
  static const Color statusConfirmed = Color(0xFF7B1FA2);
  static const Color statusPreparing = Color(0xFFF57C00);
  static const Color statusReady = Color(0xFF388E3C);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFD32F2F);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFC1121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSizes {
  AppSizes._();

  static const double p8 = 8;
  static const double p12 = 12;
  static const double p14 = 14;
  static const double p16 = 16;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;

  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double rFull = 100;

  static const double i20 = 20;

  static const double btnLarge = 54;
  static const double btnMedium = 46;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
}

class AppTheme {
  AppTheme._();

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: _appBarTheme,
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF1A1A1A)),
          displayMedium: TextStyle(color: Color(0xFF1A1A1A)),
          displaySmall: TextStyle(color: Color(0xFF1A1A1A)),
          headlineLarge: TextStyle(color: Color(0xFF1A1A1A)),
          headlineMedium: TextStyle(color: Color(0xFF1A1A1A)),
          headlineSmall: TextStyle(color: Color(0xFF1A1A1A)),
          titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
          titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
          titleSmall: TextStyle(color: Color(0xFF1A1A1A)),
          bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
          bodySmall: TextStyle(color: Color(0xFF6B6B6B)),
          labelLarge: TextStyle(color: Color(0xFF1A1A1A)),
          labelMedium: TextStyle(color: Color(0xFF1A1A1A)),
          labelSmall: TextStyle(color: Color(0xFF6B6B6B)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p14,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        appBarTheme: _appBarTheme,
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p14,
          ),
        ),
      );
}