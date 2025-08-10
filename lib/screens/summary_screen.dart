import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

// ✅ Pop-up + throttle + local notification
import 'package:khoroch/utils/alert_popups.dart';
import 'package:khoroch/utils/budget_alert_guard.dart';
import 'package:khoroch/utils/notification_helper.dart';

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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBudgetsAndSpendings();
  }

  @override
  void didUpdateWidget(covariant SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _loadBudgetsAndSpendings();
    }
  }

  Future<void> _loadBudgetsAndSpendings() async {
    final now = DateTime.now();
    final selectedMonth = DateTime(now.year, now.month);

    final budgets =
        await DatabaseHelper.instance.getBudgetsForMonth(selectedMonth);
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final daily = <BudgetCategory, double>{};
    final monthly = <BudgetCategory, double>{};

    // ⚠️ Do not change the positive/negative logic:
    // You are summing entries where amount > 0 as spending.
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

    if (!mounted) return;
    setState(() {
      _selectedMonth = selectedMonth;
      _budgetMap = {for (var b in budgets) b.category: b.amount};
      _monthlySpending = monthly;
      _dailySpending = daily;
      _loaded = true;
    });

    // Run thresholds AFTER first frame so dialogs can show
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkThresholds(context);
    });
  }

  Future<void> _checkThresholds(BuildContext context) async {
    if (!_loaded) return;

    for (final cat in BudgetCategory.values) {
      final limit = _budgetMap[cat] ?? 0;
      if (limit <= 0) continue; // skip categories with no budget set

      final spent = _monthlySpending[cat] ?? 0; // already using your positive values

      if (spent > limit) {
        await _notifyExceeded(
          context,
          categoryName: cat.name,
          spent: spent,
          limit: limit,
          month: _selectedMonth,
        );
      } else if (spent >= 0.8 * limit) {
        await _notifyApproaching(
          context,
          categoryName: cat.name,
          spent: spent,
          limit: limit,
          month: _selectedMonth,
        );
      }
    }
  }

  Future<void> _notifyExceeded(
    BuildContext context, {
    required String categoryName,
    required double spent,
    required double limit,
    required DateTime month,
  }) async {
    final over = (spent - limit).toStringAsFixed(0);
    final title = 'Budget Exceeded: $categoryName';
    final body =
        'You exceeded this month’s $categoryName budget by ৳$over (spent ৳${spent.toStringAsFixed(0)} of ৳${limit.toStringAsFixed(0)}).';

    final shouldShow = await BudgetAlertGuard.shouldNotify(
      categoryKey: categoryName,
      month: month,
      type: 'exceeded',
    );
    if (!shouldShow) return;

    if (mounted) {
      await AlertPopups.showBudgetPopup(
        context,
        title: title,
        message: body,
        primaryLabel: 'Open Summary',
        onPrimary: () {
          // Optionally navigate or scroll
          // Navigator.pushNamed(context, '/summary');
        },
      );
    }

    await NotificationHelper.showBudgetAlert(title: title, body: body);
  }

  Future<void> _notifyApproaching(
    BuildContext context, {
    required String categoryName,
    required double spent,
    required double limit,
    required DateTime month,
  }) async {
    final title = 'Approaching Budget: $categoryName';
    final body =
        'You’ve crossed 80% of your $categoryName budget this month (৳${spent.toStringAsFixed(0)} of ৳${limit.toStringAsFixed(0)}).';

    final shouldShow = await BudgetAlertGuard.shouldNotify(
      categoryKey: categoryName,
      month: month,
      type: 'approach',
    );
    if (!shouldShow) return;

    if (mounted) {
      await AlertPopups.showBudgetPopup(
        context,
        title: title,
        message: body,
        primaryLabel: 'Open Summary',
        onPrimary: () {
          // Navigator.pushNamed(context, '/summary');
        },
      );
    }

    await NotificationHelper.showBudgetAlert(title: title, body: body);
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
