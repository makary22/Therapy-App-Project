import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/HomeScreen.dart' show HomeScreen;
import 'features/notifications/push_notification_service.dart';
import 'features/screens/login.dart' show LoginScreen;
import 'features/screens/onboarding_screen.dart' show OnboardingScreen;
import 'features/screens/verify_email_screen.dart' show VerifyEmailScreen;
import 'features/theme/app_theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and other services but don't let network issues block startup.
  try {
    await Firebase.initializeApp().timeout(const Duration(milliseconds: 500));
    debugPrint('[main] Firebase initialized');
  } catch (_) {
    // If Firebase fails to init or times out (offline), proceed — we'll rely on cached state.
    debugPrint('[main] Firebase init failed or timed out');
  }

  // Initialize push notifications and theme controller defensively.
  try {
    await PushNotificationService.initialize()
        .timeout(const Duration(milliseconds: 500));
    debugPrint('[main] PushNotificationService initialized');
  } catch (_) {
    // Ignore initialization errors or timeouts so app can continue.
    debugPrint('[main] PushNotificationService init failed or timed out');
  }

  try {
    await AppThemeController.initialize()
        .timeout(const Duration(milliseconds: 500));
    debugPrint('[main] AppThemeController initialized');
  } catch (_) {
    // If theme init fails or times out, continue with defaults.
    debugPrint('[main] AppThemeController init failed or timed out');
  }

  final prefs = await SharedPreferences.getInstance();
  final reminderTime = prefs.getString('profile_reminder_time') ?? '08:00 AM';
  try {
    // Schedule in background; if offline, this will throw — ignore it.
    await PushNotificationService.scheduleDailyReminderFromLabel(reminderTime)
        .timeout(const Duration(milliseconds: 300));
    debugPrint('[main] Scheduled daily reminder');
  } catch (_) {}

  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  debugPrint('[main] Resolving start screen');
  final startScreen = await _resolveStartScreen(seenOnboarding: seenOnboarding)
      .timeout(const Duration(milliseconds: 800),
          onTimeout: () => const _OfflineStartScreen());
  debugPrint('[main] Resolved start screen: ${startScreen.runtimeType}');

  runApp(MyApp(startScreen: startScreen));
}

Future<Widget> _resolveStartScreen({required bool seenOnboarding}) async {
  if (!seenOnboarding) {
    return const OnboardingScreen();
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const LoginScreen();
  }
  // Try to reload the user but don't block startup on network/timeouts.
  try {
    await user.reload().timeout(const Duration(milliseconds: 500));
  } catch (_) {
    // ignore reload errors/timeouts — we'll use cached user state
  }

  final refreshedUser = FirebaseAuth.instance.currentUser;
  if (refreshedUser == null) {
    return const LoginScreen();
  }

  return refreshedUser.emailVerified
      ? const HomeScreen()
      : const VerifyEmailScreen();
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Safe Space',
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF11121A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7B5EA7),
              brightness: Brightness.dark,
            ),
          ),
          home: startScreen,
        );
      },
    );
  }
}

class _OfflineStartScreen extends StatefulWidget {
  const _OfflineStartScreen({super.key});

  @override
  State<_OfflineStartScreen> createState() => _OfflineStartScreenState();
}

class _OfflineStartScreenState extends State<_OfflineStartScreen> {
  bool _loading = false;

  Future<void> _retry() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      final resolved = await _resolveStartScreen(seenOnboarding: seenOnboarding)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => resolved));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('You appear to be offline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Connect to the internet or try again.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 18),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
