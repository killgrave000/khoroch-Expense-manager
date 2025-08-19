import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:khoroch/models/expense.dart';           // Category enum used by charts
import 'package:khoroch/models/budget.dart';            // Budget + BudgetCategory
import 'package:khoroch/database/database_helper.dart'; // getBudgetsForMonth

import 'package:khoroch/screens/budget_settings_screen.dart';
import 'package:khoroch/screens/summary_screen.dart';
import 'package:khoroch/screens/daraz_deals_screen.dart';
import 'package:khoroch/widgets/insights/monthly_insights_screen.dart';
import 'package:khoroch/screens/data_export_screen.dart';

class SidebarDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final List<Expense> expenses;

  const SidebarDrawer({
    Key? key,
    required this.onLogout,
    required this.expenses,
  }) : super(key: key);

  /// Convert your BudgetCategory (used in DB) to the Expense Category enum (used by charts).
  Category? _mapBudgetToExpenseCategory(BudgetCategory b) {
    switch (b) {
      case BudgetCategory.food:
        return Category.food;
      case BudgetCategory.leisure:
        return Category.leisure;
      case BudgetCategory.travel:
        return Category.travel;
      case BudgetCategory.work:
        return Category.work;
      case BudgetCategory.grocery:
        return Category.grocery;
      case BudgetCategory.bills:
        return Category.bills;
    }
  }

  /// Load budgets for the given month from SQLite and return Map<Category, double>
  Future<Map<Category, double>> _loadBudgetsForMonth(DateTime month) async {
    final rows = await DatabaseHelper.instance.getBudgetsForMonth(
      DateTime(month.year, month.month), // normalize to month start
    );

    final map = <Category, double>{};
    for (final Budget b in rows) {
      final c = _mapBudgetToExpenseCategory(b.category);
      if (c != null && b.amount > 0) {
        map[c] = b.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: const Text(
              'Khoroch',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          /// 📊 Charts (Monthly Insights)
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Charts'),
            onTap: () async {
              Navigator.pop(context); // close the drawer

              final month = DateTime(DateTime.now().year, DateTime.now().month);

              // Load real budgets for the selected month from SQLite
              final budgets = await _loadBudgetsForMonth(month);

              if (budgets.isEmpty) {
                // Optional UX: nudge to set budgets if none saved for this month
                final label = DateFormat.yMMM().format(month);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No budgets saved for $label. Set budgets first.')),
                );
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MonthlyInsightsScreen(
                    expenses: expenses,
                    month: month,                   // ensures charts align with loaded budgets
                    categoryBudgets: budgets,       // ✅ real saved budgets from DB
                  ),
                ),
              );
            },
          ),

          /// 💡 Saving Tips Placeholder
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Saving Tips'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Scroll or Navigate to Tips
            },
          ),

          /// 🧠 Smart Deals (Daraz + Chaldal)
          ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text('Smart Deals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DarazDealsScreen()),
              );
            },
          ),

          /// 💰 Budget Settings
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Set Budgets'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetSettingsScreen()),
              );
            },
          ),

          /// 📋 Summary Report
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('Summary'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SummaryScreen(expenses: expenses),
                ),
              );
            },
          ),

          ListTile(
  leading: const Icon(Icons.trending_up),
  title: const Text('Overspend Insights'),
  onTap: () {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/overspend-insights');
  },
),

          /// 🔓 Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),

          ListTile(
  leading: const Icon(Icons.backup_outlined),
  title: const Text('Export & Backup'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataExportScreen()),
    );
  },
),


          const Divider(),

          /// ⚙️ Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          /// ℹ️ About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Khoroch',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 MahirLabib',
              );
            },
          ),
        ],
      ),
    );
  }
}
