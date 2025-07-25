import 'dart:math';
import 'package:flutter/material.dart';

class SavingTip extends StatelessWidget {
  final List<String> tips = [
    "Put 10% of your salary into savings first.",
    "Skip one takeout meal this week and save that money.",
    "Review your subscriptions monthly.",
    "Set a no-spend day each week.",
    "Use cash instead of cards to reduce spending.",
  ];

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final tip = tips[random.nextInt(tips.length)];
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "💡 Smart Tip: $tip",
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
