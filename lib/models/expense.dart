import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

/// Expense categories
enum Category { food, travel, leisure, work, grocery, bills }

/// Icons mapped to categories
const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.travel: Icons.flight_takeoff,
  Category.leisure: Icons.movie,
  Category.grocery: Icons.local_grocery_store,
  Category.work: Icons.work,
  Category.bills: Icons.receipt_long,
};

/// Model class for a single expense
class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  /// Display-friendly date
  String get formattedDate => formatter.format(date);

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name, // enum as string
    };
  }

  /// Recreate from SQLite row
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: Category.values.firstWhere((c) => c.name == map['category']),
    );
  }
}

/// Bucket of expenses by category
class ExpenseBucket {
  const ExpenseBucket({required this.category, required this.expenses});

  /// Create a filtered bucket
  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((expense) => expense.category == category)
            .toList();

  final Category category;
  final List<Expense> expenses;

  /// Total sum in this category
  double get totalExpenses =>
      expenses.fold(0, (sum, e) => sum + e.amount);
}
