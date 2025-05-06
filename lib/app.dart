import 'package:flutter/material.dart';
import 'package:weather_mood/core/constants/app_routes.dart'; // твій файл із маршрутами

class WeatherMoodApp extends StatelessWidget {
  const WeatherMoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Mood',
      theme: ThemeData.light(), // або твоя кастомна тема
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
