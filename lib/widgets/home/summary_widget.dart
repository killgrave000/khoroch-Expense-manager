import 'package:flutter/material.dart';
import 'package:khoroch/models/expense.dart';

class SummaryWidget extends StatelessWidget {
  final List<Expense> expenses;

  const SummaryWidget({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int incomeTotal = expenses
        .where((e) => e.amount >= 0)
        .fold(0, (sum, e) => sum + e.amount.round());

    final int expenseTotal = expenses
        .where((e) => e.amount < 0)
        .fold(0, (sum, e) => sum + e.amount.abs().round());

    final int balance = incomeTotal - expenseTotal;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryColumn('Income', incomeTotal, theme),
              _divider(),
              _buildSummaryColumn('Expense', expenseTotal, theme),
              _divider(),
              _buildSummaryColumn('Balance', balance, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, int amount, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          amount.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Text(
      '|',
      style: TextStyle(
        fontSize: 30,
        color: Colors.grey,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}
