import 'package:flutter_test/flutter_test.dart';
import 'package:weather_mood/features/recommendation/recommendation_service.dart';

void main() {
  group('RecommendationService.generateLookFromItems', () {
    final items = [
      {'id': '1', 'category': 'Тіло', 'tags': ['сонячно'], 'name': 'Футболка'},
      {'id': '2', 'category': 'Голова', 'tags': ['радісний'], 'name': 'Кепка'},
      {'id': '3', 'category': 'Ноги', 'tags': [''], 'name': 'Джинси'},
      {'id': '4', 'category': 'Ступні', 'tags': [], 'name': 'Кросівки'},
      {'id': '5', 'category': 'Шия', 'tags': [], 'name': 'Шарф'},
      {'id': '6', 'category': 'Аксесуари', 'tags': [''], 'name': 'Годинник'},
      {'id': '7', 'category': 'Руки', 'tags': [''], 'name': 'Браслет'},
    ];


    test('повертає рекомендовані речі за настроєм і погодою', () async {
      final look = await RecommendationService.generateLookFromItems(
        items: items,
        mood: 'радісний',
        weather: 'сонячно',
      );

      // Має бути хоча б одна річ з тегом mood/weather
      expect(look.any((item) => item['tags'].contains('сонячно')), true);
      expect(look.any((item) => item['tags'].contains('радісний')), true);
    });

    test('заповнює відсутні категорії хоча б першими доступними речами', () async {
      final look = await RecommendationService.generateLookFromItems(
        items: items,
        mood: 'сумний',
        weather: 'сніг',
      );

      // Має бути хоча б одна річ для категорії 'Тіло', бо вона є у items
      expect(look.any((item) => item['category'] == 'Тіло'), true);
    });

    test('повертає рівно стільки речей, скільки категорій', () async {
      final look = await RecommendationService.generateLookFromItems(
        items: items,
        mood: 'спокійний',
        weather: 'вітряно',
      );

      // Категорій 7
      expect(look.length, 7);
    });
  });
}
