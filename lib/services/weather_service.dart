import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static const String _apiKey = 'e3a685c5b2f8a01bbe8eea1e7c6be6fd';

  static Future<Map<String, dynamic>> fetchWeatherByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=ua';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 🏙️ Основне джерело міста — з OpenWeatherMap
      String city = data['name'] ?? 'Невідомо';

      // 🔄 Якщо не отримали місто — fallback через reverse geocoding
      if (city.isEmpty || city.toLowerCase() == 'null') {
        try {
          List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
          if (placemarks.isNotEmpty) {
            city = placemarks.first.locality ??
                placemarks.first.subAdministrativeArea ??
                placemarks.first.administrativeArea ??
                'Невідомо';
          }
        } catch (e) {
          print('❌ Помилка reverse geocoding: $e');
        }
      }

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
