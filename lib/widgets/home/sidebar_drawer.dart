import 'package:flutter/material.dart';
import 'package:khoroch/screens/budget_settings_screen.dart';
import 'package:khoroch/screens/summary_screen.dart'; // ✅ import summary screen
import 'package:khoroch/models/expense.dart'; // required to pass expenses

class SidebarDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final List<Expense> expenses; // ✅ add expenses to constructor

  const SidebarDrawer({
    Key? key,
    required this.onLogout,
    required this.expenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Khoroch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Charts'),
            onTap: () {
              Navigator.pop(context);
              // Add chart navigation logic
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Saving Tips'),
            onTap: () {
              Navigator.pop(context);
              // Add tip section scroll or navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text('Smart Deals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/deals');
            },
          ),

          /// ✅ Budget Feature
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

          /// ✅ Summary Screen Navigation
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
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Khoroch',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 YourTeam',
              );
            },
          ),
        ],
      ),
    );
  }
}
