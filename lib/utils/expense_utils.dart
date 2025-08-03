import 'package:intl/intl.dart';
import 'package:khoroch/models/expense.dart'; // adjust the path based on your folder structure

/// Returns a map of monthly expense totals.
/// Format: {'2025-07': 1234.56, '2025-08': 789.00}
Map<String, double> getMonthlyExpenses(List<Expense> expenses) {
  final Map<String, double> summary = {};

  for (var expense in expenses) {
    final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    summary[key] = (summary[key] ?? 0) + expense.amount;
  }

  return summary;
}

/// Formats 'YYYY-MM' keys into readable strings like 'July 2025'
String formatMonthKey(String monthKey) {
  try {
    final parts = monthKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat.yMMMM().format(date); // e.g., "July 2025"
  } catch (e) {
    return monthKey; // fallback if something goes wrong
  }
}
