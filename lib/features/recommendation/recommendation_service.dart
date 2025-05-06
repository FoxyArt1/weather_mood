class RecommendationService {
  static Future<String> fetchCurrentWeather() async {
    // Поки що заглушка. Тут має бути реальний виклик до OpenWeather API або іншого джерела
    return 'сонячно';
  }

  static Future<List<Map<String, dynamic>>> generateLookFromItems({
    required List<Map<String, dynamic>> items,
    required String mood,
    required String weather,
  }) async {
    final List<String> categories = [
      'Аксесуари', 'Голова', 'Шия', 'Тіло', 'Руки', 'Ноги', 'Ступні'
    ];

    Map<String, Map<String, dynamic>> look = {};

    for (var item in items) {
      final category = item['category'] ?? '';
      final tags = (item['tags'] as List?)?.cast<String>() ?? [];

      if (!look.containsKey(category)) {
        bool matchesMood = tags.any((t) => mood.toLowerCase().contains(t.toLowerCase()));
        bool matchesWeather = tags.any((t) => weather.toLowerCase().contains(t.toLowerCase()));

        if (matchesMood || matchesWeather || look.length < 3) {
          look[category] = item;
        }
      }
    }

    // Якщо якихось категорій не вистачає — додаємо випадкові речі
    for (var cat in categories) {
      if (!look.containsKey(cat)) {
        final options = items.where((i) => i['category'] == cat).toList();
        if (options.isNotEmpty) look[cat] = options.first;
      }
    }

    return look.values.toList();
  }
}
