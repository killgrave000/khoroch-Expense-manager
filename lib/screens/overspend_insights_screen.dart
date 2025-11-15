import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:khoroch/models/expense.dart';
import 'package:khoroch/database/database_helper.dart';
import 'package:khoroch/widgets/chart/chart.dart';
import 'package:khoroch/ml/overspend_predictor.dart';

class OverspendInsightsScreen extends StatefulWidget {
  const OverspendInsightsScreen({super.key});

  @override
  State<OverspendInsightsScreen> createState() => _OverspendInsightsScreenState();
}

class _OverspendInsightsScreenState extends State<OverspendInsightsScreen> {
  late DateTime _month;
  OverspendPredictor? _predictor;
  double? _prob;
  Map<String, double>? _budgets;
  List<Expense> _monthExpenses = [];
  bool _loading = true;
  String? _error;

  static const double riskThreshold = 0.60;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _init();
  }

  Future<void> _init() async {
    try {
      final predictor = await OverspendPredictor.load();
      final expenses = await _loadMonthExpenses(_month);
      final budgets = await _loadBudgetsForMonth(_month);

      final prob = predictor.predictProbability(
        expenses: _toModelRows(expenses),
        budgets: budgets,
        month: _month,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (prob >= riskThreshold && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Heads up: High risk of overspending this month (p=${prob.toStringAsFixed(2)}).",
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      setState(() {
        _predictor = predictor;
        _monthExpenses = expenses;
        _budgets = budgets;
        _prob = prob;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _predictor?.close();
    super.dispose();
  }

  // =============================================================
  // DATA HELPERS
  // =============================================================

  Future<List<Expense>> _loadMonthExpenses(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(days: 1));

    try {
      final all = await DatabaseHelper.instance.getAllExpenses();
      return all.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)).toList();
    } catch (_) {
      return <Expense>[];
    }
  }

  // FIXED: Load budgets from DB
  Future<Map<String, double>> _loadBudgetsForMonth(DateTime month) async {
    try {
      final list = await DatabaseHelper.instance.getBudgetsForMonth(month);

if (list.isNotEmpty) {
  final map = <String, double>{};

  for (final b in list) {
    final key = b.category.name.toLowerCase();
    map[key] = b.amount;
  }

  return map;
}

    } catch (_) {}

    // Fallback ONLY if DB empty
    final txt = await rootBundle.loadString('assets/data/khoroch_month_budget_202508.json');
    final m = json.decode(txt) as Map<String, dynamic>;
    final budgets = (m['budgets'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k.toString().toLowerCase(), (v as num).toDouble()),
    );
    return budgets;
  }

  List<Map<String, dynamic>> _toModelRows(List<Expense> expenses) => expenses.map((e) => {
        "title": e.title,
        "amount": e.amount,
        "date": e.date,
        "category": e.category.name.toLowerCase(),
      }).toList();

  // =============================================================
  // COMPUTED VALUES
  // =============================================================

  double get _spendMtd {
    final now = DateTime.now();
    final sameMonth = now.year == _month.year && now.month == _month.month;
    final dayCut = sameMonth ? now.day : DateUtils.getDaysInMonth(_month.year, _month.month);

    return _monthExpenses
        .where((e) => e.date.day <= dayCut)
        .fold<double>(0.0, (s, e) => s + e.amount);
  }

  double get _totalBudget => (_budgets ?? {}).values.fold<double>(0.0, (s, v) => s + v);

  // =============================================================
  // UI HELPERS
  // =============================================================

  Widget _riskChip() {
    final p = _prob ?? 0.0;
    final isHigh = p >= riskThreshold;
    final color = isHigh ? Colors.red : Colors.green;
    final label = isHigh ? 'High Risk' : 'Low Risk';

    return Chip(
      backgroundColor: color.withOpacity(.12),
      side: BorderSide(color: color),
      label: Text('$label • p=${p.toStringAsFixed(2)}',
          style: TextStyle(color: color)),
    );
  }

  Color _chartAccentColor() {
    final p = _prob ?? 0.0;
    if (p >= 0.80) return Colors.red;
    if (p >= 0.60) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(_month);

    return Scaffold(
      appBar: AppBar(
        title: Text('Overspend Insights • $monthLabel'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _init,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              title: 'Spent (MTD)',
                              value: NumberFormat.compactCurrency(symbol: '৳').format(_spendMtd),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiCard(
                              title: 'Budget (Total)',
                              value: NumberFormat.compactCurrency(symbol: '৳').format(_totalBudget),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _KpiCard(title: 'Overspend Risk', trailing: _riskChip()),
                      const SizedBox(height: 16),

                      _ChartBlock(
                        expenses: _monthExpenses,
                        accent: _chartAccentColor(),
                        riskProb: _prob ?? 0.0,
                      ),

                      const SizedBox(height: 16),
                      if (_budgets != null && _budgets!.isNotEmpty)
                        _BudgetList(budgets: _budgets!, expenses: _monthExpenses),
                    ],
                  ),
                ),
    );
  }
}

// ===================================================================
// UI WIDGETS
// ===================================================================

class _KpiCard extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? trailing;

  const _KpiCard({required this.title, this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      value!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
              ]),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ChartBlock extends StatelessWidget {
  final List<Expense> expenses;
  final Color accent;
  final double riskProb;

  const _ChartBlock({
    required this.expenses,
    required this.accent,
    required this.riskProb,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Text('Spending by Category', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent),
                  ),
                  child: Text(
                    'Risk ${(riskProb * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Chart(expenses: expenses),
          ),
        ],
      ),
    );
  }
}

class _BudgetList extends StatelessWidget {
  final Map<String, double> budgets;
  final List<Expense> expenses;

  const _BudgetList({required this.budgets, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final mtd = expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month && e.date.day <= now.day,
    );

    final byCat = <String, double>{};
    for (final e in mtd) {
      final k = e.category.name.toLowerCase();
      byCat[k] = (byCat[k] ?? 0) + e.amount;
    }

    final keys = budgets.keys.toList()..sort();

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Text('Budget vs Spent (MTD)', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),

          ...keys.map((k) {
            final b = budgets[k] ?? 0.0;
            final s = byCat[k] ?? 0.0;
            final over = s > b && b > 0;

            return ListTile(
              dense: true,
              title: Text(k[0].toUpperCase() + k.substring(1)),
              subtitle: LinearProgressIndicator(
                value: b > 0 ? (s / b).clamp(0.0, 1.0) : 0.0,
                minHeight: 6,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${s.toStringAsFixed(0)} / ৳${b.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: over ? Colors.red : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (over)
                    const Text(
                      'Overspent',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
