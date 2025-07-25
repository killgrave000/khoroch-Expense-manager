import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

/// Expense categories
enum Category { food, travel, leisure, work, grocery }

/// Icons mapped to categories
const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.travel: Icons.flight_takeoff,
  Category.leisure: Icons.movie,
  Category.grocery: Icons.local_grocery_store,
  Category.work: Icons.work,
};

/// Model class for a single expense
class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    String? id,
  }) : id = id ?? uuid.v4(); // optional for fromMap()

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  /// Format date for display
  String get formattedDate {
    return formatter.format(date);
  }

  /// Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name, // Save enum as string
    };
  }

  /// Create Expense object from database Map
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

/// A container for all expenses of a single category
class ExpenseBucket {
  const ExpenseBucket({required this.category, required this.expenses});

  /// Create a bucket for a specific category from a list of all expenses
  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses =
            allExpenses.where((expense) => expense.category == category).toList();

  final Category category;
  final List<Expense> expenses;

  /// Calculate total amount spent in this category
  double get totalExpenses {
    double sum = 0;
    for (final expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }
}
