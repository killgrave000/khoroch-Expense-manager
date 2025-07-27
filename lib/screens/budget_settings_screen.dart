import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final Map<BudgetCategory, TextEditingController> _controllers = {};
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    for (var category in BudgetCategory.values) {
      _controllers[category] = TextEditingController();
    }
    _loadBudgets(); // Load budgets for selected month
  }

  Future<void> _loadBudgets() async {
    print("📥 Loading budgets for ${_selectedMonth.year}-${_selectedMonth.month}");
    final budgets = await DatabaseHelper.instance.getBudgetsForMonth(_selectedMonth);
    for (final budget in budgets) {
      _controllers[budget.category]?.text = budget.amount.toStringAsFixed(0);
    }
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    print("🚀 Saving budgets for ${_selectedMonth.year}-${_selectedMonth.month}");

    for (var category in BudgetCategory.values) {
      final text = _controllers[category]!.text;
      final value = double.tryParse(text);
      print("  ➤ ${category.name}: input = '$text' → value = $value");

      if (value != null) {
        await DatabaseHelper.instance.insertOrUpdateBudget(
          Budget(
            category: category,
            amount: value,
            month: _selectedMonth,
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budgets saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  void _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Budget Month',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _loadBudgets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> budgetInputs = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Budget for ${DateFormat.yMMM().format(_selectedMonth)}",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: () => _pickMonth(context),
            child: const Text("Change Month"),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...BudgetCategory.values.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: _controllers[category],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Budget for ${category.name}",
              border: const OutlineInputBorder(),
            ),
          ),
        );
      }).toList(),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ElevatedButton(
          onPressed: _saveBudgets,
          child: const Text("Save Budgets"),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Set Budgets")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: budgetInputs,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
