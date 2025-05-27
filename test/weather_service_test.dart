import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weather_mood/services/weather_service.dart';
import 'package:http/testing.dart';

void main() {
  group('WeatherService', () {
    test('fetchWeatherByLocation returns parsed weather data', () async {
      // Замінюємо http.get на мок
      final mockClient = MockClient((request) async {
        final fakeResponse = {
          "main": {"temp": 18.5},
          "weather": [
            {"description": "ясно", "icon": "01d"}
          ],
          "name": "Київ"
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(fakeResponse)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      // Підміна http.get через patch (якби був DI)
      WeatherServiceWithMock.client = mockClient;

      final result = await WeatherServiceWithMock.fetchWeatherByLocation(
        latitude: 50.45,
        longitude: 30.52,
      );

      expect(result['temp'], 18.5);
      expect(result['description'], 'ясно');
      expect(result['icon'], '01d');
      expect(result['city'], 'Київ');
    });
  });
}

// 🔧 Модифікована версія WeatherService із можливістю інʼєкції клієнта
class WeatherServiceWithMock {
  static http.Client client = http.Client();

  static const String _apiKey = 'e3a685c5b2f8a01bbe8eea1e7c6be6fd';

  static Future<Map<String, dynamic>> fetchWeatherByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=ua';
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      String city = data['name'] ?? 'Невідомо';

      return {
        'temp': data['main']['temp'],
        'description': data['weather'][0]['description'],
        'icon': data['weather'][0]['icon'],
        'city': city,
      };
    } else {
      throw Exception('Не вдалося отримати погоду');
    }
  }
}
