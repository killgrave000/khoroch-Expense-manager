import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:khoroch/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: themeProvider.isDarkMode,
        onChanged: themeProvider.toggleTheme,
      ),
    );
  }
}
