import 'package:flutter/material.dart';

class ExpenseCategory {
  static const all = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Salary',
    'Other',
  ];

  static IconData iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt_long;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.local_hospital;
      case 'Salary':
        return Icons.payments;
      default:
        return Icons.category;
    }
  }
}

class Expense {
  final String? id;
  final String name;
  final double amount;
  final String category;
  final bool isExpense;
  final DateTime? createdAt;

  const Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.isExpense,
    this.createdAt,
  });

  /// Positive for income, negative for expenses.
  double get signedAmount => isExpense ? -amount : amount;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      isExpense: json['is_expense'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  /// Omits server-generated fields when they are null so inserts use defaults.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'is_expense': isExpense,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
    };
  }
}
