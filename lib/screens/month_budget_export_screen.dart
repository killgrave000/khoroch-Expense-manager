import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:khoroch/database/database_helper.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/services/month_budget_export_service.dart';

class MonthBudgetExportScreen extends StatefulWidget {
  const MonthBudgetExportScreen({super.key});

  @override
  State<MonthBudgetExportScreen> createState() => _MonthBudgetExportScreenState();
}

class _MonthBudgetExportScreenState extends State<MonthBudgetExportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Future<List<Budget>>? _loadFuture;
  String? _lastSavedPath;
  String? _jsonPreview;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _loadFuture = DatabaseHelper.instance.getBudgetsForMonth(
        DateTime(_selectedMonth.year, _selectedMonth.month),
      );
      _jsonPreview = null;
      _lastSavedPath = null;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2035, 12),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _refresh();
    }
  }

  Future<void> _exportJson() async {
    setState(() => _exporting = true);
    try {
      final path = await MonthBudgetExportService.saveAndShareMonthBudgetJson(
        month: _selectedMonth,
        shareAfter: true, // opens Share sheet
      );
      if (!mounted) return;
      setState(() => _lastSavedPath = path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _previewJson() async {
    try {
      final json = await MonthBudgetExportService.buildMonthBudgetJson(_selectedMonth);
      if (!mounted) return;
      setState(() => _jsonPreview = json);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $e')),
      );
    }
  }

  Future<void> _copyJson() async {
    try {
      final json = _jsonPreview ??
          await MonthBudgetExportService.buildMonthBudgetJson(_selectedMonth);
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON copied to clipboard')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMM().format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget JSON Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Change month',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: FutureBuilder<List<Budget>>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? const <Budget>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Budgets for $label',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickMonth,
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (items.isEmpty)
                Card(
                  color: Colors.amber.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No budgets saved for this month.'),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: items.map((b) {
                        return ListTile(
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                          title: Text(b.category.name),
                          trailing: Text('৳${b.amount.toStringAsFixed(0)}'),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              if (_lastSavedPath != null)
                Text(
                  'Last exported: $_lastSavedPath',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

              const SizedBox(height: 12),

              // Action buttons
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _exporting ? null : _exportJson,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.ios_share_rounded),
                    label: const Text('Export & Share JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _previewJson,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyJson,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy JSON'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_jsonPreview != null)
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _jsonPreview!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
