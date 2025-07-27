import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

class SummaryScreen extends StatefulWidget {
  final List<Expense> expenses;

  const SummaryScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<BudgetCategory, double> _budgetMap = {};
  Map<BudgetCategory, double> _monthlySpending = {};
  Map<BudgetCategory, double> _dailySpending = {};

  @override
  void initState() {
    super.initState();
    _loadBudgetsAndSpendings();
  }

  Future<void> _loadBudgetsAndSpendings() async {
    final now = DateTime.now();
    final selectedMonth = DateTime(now.year, now.month);

    final budgets = await DatabaseHelper.instance.getBudgetsForMonth(selectedMonth);
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final daily = <BudgetCategory, double>{};
    final monthly = <BudgetCategory, double>{};

    for (final expense in widget.expenses.where((e) => e.amount > 0)) {
      final budgetCat = _mapExpenseToBudgetCategory(expense.category);
      final date = expense.date;

      if (!date.isBefore(startOfMonth)) {
        monthly[budgetCat] = (monthly[budgetCat] ?? 0) + expense.amount;
      }

      if (!date.isBefore(startOfDay)) {
        daily[budgetCat] = (daily[budgetCat] ?? 0) + expense.amount;
      }
    }

    setState(() {
      _budgetMap = {for (var b in budgets) b.category: b.amount};
      _monthlySpending = monthly;
      _dailySpending = daily;
    });
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
      case Category.bills:
        return BudgetCategory.bills;
      default:
        return BudgetCategory.food;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDaily = _dailySpending.values.fold(0.0, (a, b) => a + b);
    final totalMonthly = _monthlySpending.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text("Budget & Spending Summary")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // ✅ Total Summary Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spending Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Today: ৳${totalDaily.toStringAsFixed(0)}'),
                    Text('This Month: ৳${totalMonthly.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Per-category Breakdown Cards
            ...BudgetCategory.values.map((category) {
              final budget = _budgetMap[category] ?? 0;
              final spentMonthly = _monthlySpending[category] ?? 0;
              final spentDaily = _dailySpending[category] ?? 0;
              final overspent = spentMonthly > budget;

              return Card(
                color: overspent ? Colors.red[50] : null,
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(category.name.toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Budget: ৳${budget.toStringAsFixed(0)}"),
                      Text("Spent This Month: ৳${spentMonthly.toStringAsFixed(0)}"),
                      Text("Spent Today: ৳${spentDaily.toStringAsFixed(0)}"),
                    ],
                  ),
                  trailing: Text(
                    overspent
                        ? "Over!"
                        : "৳${(budget - spentMonthly).toStringAsFixed(0)} left",
                    style: TextStyle(
                      color: overspent ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
