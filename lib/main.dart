import 'package:flutter/material.dart';
import 'theme/app_theme.dart';  // 👈 import the theme

import 'home/ui/home_page.dart';


void main() {
  runApp(const AnimalRestaurantApp());
}

class AnimalRestaurantApp extends StatelessWidget {
  const AnimalRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Restaurant Tracker',
      debugShowCheckedModeBanner: false,     // 👈 removes debug banner
      theme: buildAppTheme(),                // 👈 your global theme
      home: const HomePage(),
    );
  }
}