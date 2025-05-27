import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_mood/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage shows required fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    // Заголовок сторінки
    expect(find.text('Реєстрація'), findsOneWidget);

    // Поля введення
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Пароль'), findsOneWidget);

    // Кнопка
    expect(find.widgetWithText(ElevatedButton, 'Зареєструватись'), findsOneWidget);

    // Перевірка, що НЕМАЄ кнопки "Вже маєте акаунт?" — для надійності
    expect(find.textContaining('акаунт'), findsNothing);
  });
}
