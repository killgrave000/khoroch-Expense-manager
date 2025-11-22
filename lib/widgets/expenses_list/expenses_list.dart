import 'package:flutter/material.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/widgets/expenses_list/expense_item.dart';
import 'package:khoroch/utils/expense_utils.dart';

// UPDATED: Added controller parameter
class ExpensesList extends StatelessWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
    this.controller,
  });

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;

  // NEW
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final monthlySummary = getMonthlyExpenses(expenses);

    return ListView(
      controller: controller, // NEW: attach scroll controller
      children: [
        // Monthly Summary Section
        if (monthlySummary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...monthlySummary.entries.map((entry) {
                  return Text(
                    '${formatMonthKey(entry.key)}: ৳${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  );
                }).toList(),
              ],
            ),
          ),

        // Expense List Section
        ...expenses.map((expense) {
          return Dismissible(
            key: ValueKey(expense),
            background: Container(
              color: Theme.of(context).colorScheme.error.withOpacity(0.75),
              margin: EdgeInsets.symmetric(
                horizontal: Theme.of(context).cardTheme.margin!.horizontal,
              ),
            ),
            onDismissed: (direction) {
              onRemoveExpense(expense);
            },
            child: ExpenseItem(expense),
          );
        }).toList(),
      ],
    );
  }
}
