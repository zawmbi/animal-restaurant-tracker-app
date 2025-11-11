import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'home/ui/home_page.dart';
import 'features/auth/auth_gate.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnimalRestaurantApp());
}

class AnimalRestaurantApp extends StatelessWidget {
  const AnimalRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Restaurant Tracker',
      debugShowCheckedModeBanner: false,     // 
      theme: buildAppTheme(),                // 
      home: const AuthGate(child: HomePage()),
    );
  }
}
