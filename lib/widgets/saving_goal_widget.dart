import 'package:flutter/material.dart';
import 'package:khoroch/services/export_csv_service.dart';


class SavingGoalWidget extends StatelessWidget {
  final double target;
  final double current;

  const SavingGoalWidget({required this.target, required this.current, super.key});

  @override
  Widget build(BuildContext context) {
    final percent = (current / target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("🎯 Savings Goal: ৳${target.toStringAsFixed(0)}"),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: percent),
            const SizedBox(height: 8),
            Text("Saved: ৳${current.toStringAsFixed(0)}"),

            IconButton(
  icon: const Icon(Icons.download_rounded),
  tooltip: 'Export CSV',
  onPressed: () async {
    try {
      final path = await ExportCsvService.exportExpensesHistoryCsv(shareAfter: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV ready: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  },
),



          ],
        ),
      ),
    );
  }
}
