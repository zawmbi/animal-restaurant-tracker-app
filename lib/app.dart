import 'package:flutter/material.dart';
import 'features/customers/ui/customers_page.dart';

class ARTrackerApp extends StatelessWidget {
  const ARTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // <-- hides the red "DEBUG" banner
      title: 'Animal Restaurant Progress Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 0, 242)),
        useMaterial3: true,
      ),
      home: const CustomersPage(),
    );

  }
}