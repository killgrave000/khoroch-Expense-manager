import 'package:flutter/material.dart';
import 'package:khoroch/models/budget.dart';
import 'package:khoroch/database/database_helper.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final Map<BudgetCategory, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var category in BudgetCategory.values) {
      _controllers[category] = TextEditingController();
    }
  }

  Future<void> _saveBudgets() async {
    for (var category in BudgetCategory.values) {
      final text = _controllers[category]!.text;
      final value = double.tryParse(text);
      if (value != null) {
        await DatabaseHelper.instance.insertOrUpdateBudget(
          Budget(category: category, amount: value),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> budgetInputs = BudgetCategory.values.map((category) {
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
    }).toList();

    budgetInputs.add(
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ElevatedButton(
          onPressed: _saveBudgets,
          child: const Text("Save Budgets"),
        ),
      ),
    );

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
