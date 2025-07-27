import 'package:flutter/material.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

class SummaryWidget extends StatefulWidget {
  final List<Expense> expenses;

  const SummaryWidget({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  @override
  State<SummaryWidget> createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  Map<BudgetCategory, double> _budgetMap = {};

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await DatabaseHelper.instance.getBudgets();
    setState(() {
      _budgetMap = {for (var b in budgets) b.category: b.amount};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int incomeTotal = widget.expenses
        .where((e) => e.amount >= 0)
        .fold(0, (sum, e) => sum + e.amount.round());

    final int expenseTotal = widget.expenses
        .where((e) => e.amount < 0)
        .fold(0, (sum, e) => sum + e.amount.abs().round());

    final int balance = incomeTotal - expenseTotal;

    // Check overspending across all budgets
    final Map<BudgetCategory, double> spentByCategory = {};
    for (final expense in widget.expenses.where((e) => e.amount < 0)) {
      final category = _mapExpenseToBudgetCategory(expense.category);
      spentByCategory[category] = (spentByCategory[category] ?? 0) + expense.amount.abs();
    }

    final List<String> overspentCategories = [];
    spentByCategory.forEach((category, spent) {
      final limit = _budgetMap[category] ?? double.infinity;
      if (spent > limit) {
        overspentCategories.add(category.name);
      }
    });

    return Column(
      children: [
        if (overspentCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Overspent on: ${overspentCategories.join(', ')}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        Padding(
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
        ),
      ],
    );
  }

  BudgetCategory _mapExpenseToBudgetCategory(Category category) {
    switch (category) {
      case Category.food:
        return BudgetCategory.food;
      case Category.leisure:
        return BudgetCategory.leisure;
      case Category.travel:
        return BudgetCategory.travel;
      case Category.work:
        return BudgetCategory.work;
      case Category.grocery:
        return BudgetCategory.grocery;
      default:
        return BudgetCategory.food;
    }
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
