import 'package:flutter/material.dart';

class AlertPopups {
  static Future<void> showBudgetPopup(
    BuildContext context, {
    required String title,
    required String message,
    String primaryLabel = 'View details',
    String secondaryLabel = 'Close',
    VoidCallback? onPrimary,
  }) async {
    final nav = Navigator.of(context);
    if (!nav.mounted) return; // ✅ valid mounted check

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message, style: const TextStyle(height: 1.35)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(secondaryLabel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onPrimary?.call();
              },
              child: Text(primaryLabel),
            ),
          ],
        );
      },
    );
  }
}
