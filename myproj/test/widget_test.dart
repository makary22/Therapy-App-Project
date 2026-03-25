import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myproj/features/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('Safe Space'), findsOneWidget);
  });
}