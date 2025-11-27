import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'home/ui/home_page.dart';
import 'package:animal_restaurant_tracker/features/timers/data/timer_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimerService.instance.init();
  runApp(const AnimalRestaurantApp());
}
class AnimalRestaurantApp extends StatelessWidget {
  const AnimalRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Restaurant Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(), // 👈 this is your starting screen
    );
  }
}
