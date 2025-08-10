import 'package:flutter/material.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

// ✅ Pop-up + throttle + notification
import 'package:khoroch/utils/alert_popups.dart';
import 'package:khoroch/utils/budget_alert_guard.dart';
import 'package:khoroch/utils/notification_helper.dart';

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
  bool _budgetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  @override
  void didUpdateWidget(covariant SummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If expenses changed, re-check after the next frame (when the widget is visible)
    if (_budgetsLoaded && oldWidget.expenses != widget.expenses) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkOverspending(context);
      });
    }
  }

  Future<void> _loadBudgets() async {
    final budgets = await DatabaseHelper.instance.getBudgets();
    if (!mounted) return;
    setState(() {
      _budgetMap = {for (var b in budgets) b.category: b.amount};
      _budgetsLoaded = true;
    });

    // ✅ Run after first frame so dialogs can actually show
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkOverspending(context);
    });
  }

  Future<void> _checkOverspending(BuildContext context) async {
    // Aggregate spending by category (negative amounts are expenses)
    final Map<BudgetCategory, double> spentByCategory = {};
    for (final expense in widget.expenses.where((e) => e.amount < 0)) {
      final category = _mapExpenseToBudgetCategory(expense.category);
      spentByCategory[category] =
          (spentByCategory[category] ?? 0) + expense.amount.abs();
    }

    final DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

    // Evaluate thresholds per category
    for (final entry in spentByCategory.entries) {
      final category = entry.key;
      final spent = entry.value;
      final limit = _budgetMap[category] ?? double.infinity;

      // Skip if no limit set
      if (limit == double.infinity || limit <= 0) continue;

      if (spent > limit) {
        await _notifyExceeded(
          context,
          categoryName: category.name,
          spent: spent,
          limit: limit,
          month: month,
        );
      } else if (spent >= 0.8 * limit) {
        await _notifyApproaching(
          context,
          categoryName: category.name,
          spent: spent,
          limit: limit,
          month: month,
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

    // In‑app pop‑up
    if (mounted) {
      await AlertPopups.showBudgetPopup(
        context,
        title: title,
        message: body,
        primaryLabel: 'Open Summary',
        onPrimary: () {
          // TODO: Navigate to a summary route if you have one:
          // Navigator.pushNamed(context, '/summary');
        },
      );
    }

    // System tray notification
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

    // In‑app pop‑up
    if (mounted) {
      await AlertPopups.showBudgetPopup(
        context,
        title: title,
        message: body,
        primaryLabel: 'Open Summary',
        onPrimary: () {
          // TODO: Navigate to a summary route if you have one:
          // Navigator.pushNamed(context, '/summary');
        },
      );
    }

    // System tray notification
    await NotificationHelper.showBudgetAlert(title: title, body: body);
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

    // For the red banner summary
    final Map<BudgetCategory, double> spentByCategory = {};
    for (final expense in widget.expenses.where((e) => e.amount < 0)) {
      final category = _mapExpenseToBudgetCategory(expense.category);
      spentByCategory[category] =
          (spentByCategory[category] ?? 0) + expense.amount.abs();
    }

    final List<String> overspentCategories = [];
    spentByCategory.forEach((category, spent) {
      final limit = _budgetMap[category] ?? double.infinity;
      if (limit != double.infinity && spent > limit) {
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
      case Category.bills:
        return BudgetCategory.bills;
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
