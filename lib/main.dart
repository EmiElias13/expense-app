import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/expense_service.dart';

void main() {
  runApp(ExpenseTrackerApp(service: ExpenseService()));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, required this.service});

  final ExpenseService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(service: service),
    );
  }
}
