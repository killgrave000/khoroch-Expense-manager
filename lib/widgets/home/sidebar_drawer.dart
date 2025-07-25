import 'package:flutter/material.dart';

class SidebarDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const SidebarDrawer({Key? key, required this.onLogout}) : super(key: key);

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
              Navigator.pop(context); // Close drawer
              Navigator.pushNamed(context, '/deals');
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
