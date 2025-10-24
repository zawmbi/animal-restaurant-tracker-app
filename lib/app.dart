import 'package:flutter/material.dart';
import 'features/customers/ui/customers_page.dart';

class ARTrackerApp extends StatelessWidget {
  const ARTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Restaurant Progress Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD900)),
        useMaterial3: true,
      ),
      home: const CustomersPage(),
    );
  }
}