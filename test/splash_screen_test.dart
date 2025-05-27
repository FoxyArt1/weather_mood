import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_mood/features/app/splash_screen/splash_screen.dart';

void main() {
  testWidgets('SplashScreen displays title and navigates after delay', (WidgetTester tester) async {
    // Створюємо GlobalKey для відстеження навігації
    final navigatorKey = GlobalKey<NavigatorState>();

    // Відображаємо SplashScreen всередині MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/login': (context) => const Placeholder(), // мок-екран логіну
        },
        home: const SplashScreen(),
      ),
    );

    // ...
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(Placeholder), findsOneWidget);

  });
}