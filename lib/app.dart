import 'package:flutter/material.dart';
import 'home/ui/home_page.dart'; // <-- use HomePage, not CustomersPage

class ARTrackerApp extends StatelessWidget {
  const ARTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Animal Restaurant Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 0, 242),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(), // <-- start on Home
    );
  }
}
