import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/order_monitor_service.dart';
import 'database/database_helper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/customer/screens/customer_home_screen.dart';
import 'features/staff/screens/staff_home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Fail loudly rather than shipping a release build that sends bearer tokens
  // in cleartext. This must not be an assert - asserts are stripped from
  // release builds, which is exactly where the check matters.
  if (kReleaseMode && ApiConstants.isCleartext) {
    throw StateError(
      'Release builds require an https:// API base URL. Got '
      '"${ApiConstants.baseUrl}". Pass one at build time, e.g. '
      'flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api',
    );
  }

  // Initialize services
  await StorageService().init();
  ApiService().init();

  // Initialize local database for caching
  await DatabaseHelper().database;

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize foreground service (Android only)
  if (Platform.isAndroid) {
    await OrderMonitorService().initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            supportedLocales: LanguageProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// Splash Screen - checks authentication and navigates
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storageService = StorageService();

    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if user has seen onboarding
    final hasSeenOnboarding = storageService.hasSeenOnboarding();

    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
      return;
    }

    // Check authentication
    await authProvider.initialize();

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      // Start foreground service for customers on Android
      if (Platform.isAndroid && authProvider.isCustomer) {
        final orderMonitorService = OrderMonitorService();
        // The task handler reads tokens from secure storage itself; it only
        // needs to know a customer is signed in.
        await orderMonitorService.saveUserCredentials(userRole: 'customer');
        // Request notification permission and start service
        await NotificationService().requestPermissions();
        await orderMonitorService.start();
      }

      if (!mounted) return;

      // Navigate based on user role
      if (authProvider.isCustomer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CustomerHomeScreen(),
          ),
        );
      } else if (authProvider.isStaff || authProvider.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const StaffHomeScreen(),
          ),
        );
      }
    } else {
      // Stop foreground service when not authenticated
      if (Platform.isAndroid) {
        final orderMonitorService = OrderMonitorService();
        await orderMonitorService.stop();
        await orderMonitorService.clearUserCredentials();
      }

      if (!mounted) return;

      // Navigate to Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_laundry_service,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
