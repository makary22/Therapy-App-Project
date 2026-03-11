import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/HomeScreen.dart' show HomeScreen;
import 'features/onboarding/onboarding_screen.dart' show OnboardingScreen;


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {

  final bool seenOnboarding;

  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Space',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home: seenOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}