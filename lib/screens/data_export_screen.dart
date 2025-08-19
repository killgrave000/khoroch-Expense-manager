import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khoroch/widgets/saving_goal_widget.dart';
import 'package:khoroch/database/database_helper.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/services/month_budget_export_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  // ---- Savings Goal (for CSV section) ----
  double _goalTarget = 0;
  double _goalCurrent = 0;
  bool _loadingGoal = true;

  // ---- Monthly Budget JSON section ----
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Future<List<Budget>>? _budgetsFuture;
  String? _jsonPreview;
  String? _lastSavedPath;
  bool _exportingJson = false;

  @override
  void initState() {
    super.initState();
    _loadSavingsGoal();
    _reloadBudgets();
  }

  // Load goal from SharedPreferences (adjust keys if you use different storage)
  Future<void> _loadSavingsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goalTarget = prefs.getDouble('saving_goal_target') ?? 50000; // sensible default
      _goalCurrent = prefs.getDouble('saving_goal_current') ?? 0;
      _loadingGoal = false;
    });
  }

  void _reloadBudgets() {
    setState(() {
      _budgetsFuture = DatabaseHelper.instance.getBudgetsForMonth(
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
      _reloadBudgets();
    }
  }

  Future<void> _exportMonthJson() async {
    setState(() => _exportingJson = true);
    try {
      final path = await MonthBudgetExportService.saveAndShareMonthBudgetJson(
        month: _selectedMonth,
        shareAfter: true,
      );
      if (!mounted) return;
      setState(() => _lastSavedPath = path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported JSON: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingJson = false);
    }
  }

  Future<void> _previewMonthJson() async {
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

  Future<void> _copyMonthJson() async {
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
    final monthLabel = DateFormat.yMMM().format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // -----------------------------------
          // Section A: Savings Goal + CSV export
          // -----------------------------------
          Text('Savings Goal & CSV Export', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_loadingGoal)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            SavingGoalWidget(target: _goalTarget, current: _goalCurrent),

          const SizedBox(height: 20),

          // -----------------------------------
          // Section B: Monthly Budget -> JSON
          // -----------------------------------
          Row(
            children: [
              Expanded(
                child: Text('Monthly Budget → JSON',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              TextButton.icon(
                onPressed: _pickMonth,
                icon: const Icon(Icons.calendar_month),
                label: Text(monthLabel),
              ),
            ],
          ),

          FutureBuilder<List<Budget>>(
            future: _budgetsFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snap.hasError) {
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snap.error}'),
                  ),
                );
              }
              final items = snap.data ?? const <Budget>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _exportingJson ? null : _exportMonthJson,
                        icon: _exportingJson
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.ios_share_rounded),
                        label: const Text('Export & Share JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewMonthJson,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Preview JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _copyMonthJson,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy JSON'),
                      ),
                    ],
                  ),

                  if (_lastSavedPath != null) ...[
                    const SizedBox(height: 8),
                    Text('Last exported: $_lastSavedPath',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],

                  if (_jsonPreview != null) ...[
                    const SizedBox(height: 12),
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
