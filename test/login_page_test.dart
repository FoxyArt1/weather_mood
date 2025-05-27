import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_mood/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage shows all expected UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    // Перевірка заголовка
    expect(find.text('Вхід'), findsOneWidget);

    // Поля вводу
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Пароль'), findsOneWidget);

    // Кнопка входу
    expect(find.widgetWithText(ElevatedButton, 'Увійти'), findsOneWidget);

    // Посилання на реєстрацію
    expect(find.text('Немає акаунту? Зареєструватись'), findsOneWidget);
  });
}
