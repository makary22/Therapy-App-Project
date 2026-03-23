import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/HomeScreen.dart' show HomeScreen;
import 'features/notifications/push_notification_service.dart';
import 'features/screens/login.dart' show LoginScreen;
import 'features/screens/onboarding_screen.dart' show OnboardingScreen;
import 'features/screens/verify_email_screen.dart' show VerifyEmailScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushNotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final startScreen = await _resolveStartScreen(seenOnboarding: seenOnboarding);

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

 
  try {
    await user.reload().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        
        debugPrint('User reload timed out, using cached data');
      },
    );
  } catch (e) {
    debugPrint('User reload failed: $e');
   
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Space',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home: startScreen,
    );
  }
}
