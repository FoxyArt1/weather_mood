import 'package:flutter/material.dart';
import 'package:weather_mood/features/app/splash_screen/splash_screen.dart';
import 'package:weather_mood/features/auth/presentation/pages/login_page.dart' as login;
import 'package:weather_mood/features/auth/presentation/pages/register_page.dart' as register;
import 'package:weather_mood/features/home/pages/home_page.dart';
import 'package:weather_mood/features/profile/pages/profile_page.dart';
import 'package:weather_mood/features/profile/pages/add_clothing_page.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const login.LoginPage(),
  '/register': (context) => const register.RegisterPage(),
  '/home': (context) => const HomePage(),
  '/profile': (context) => const ProfilePage(),
  '/add-clothing': (context) => const AddClothingPage(),

};


