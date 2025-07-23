import 'package:flutter/material.dart';
import 'package:khoroch/widgets/chart/chart.dart';
import 'package:khoroch/widgets/expenses_list/expenses_list.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/widgets/new_expense.dart';
import 'package:khoroch/widgets/saving_tip.dart';
import 'package:khoroch/widgets/home/month_year_picker_widget.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = [
    Expense(
      title: 'Course',
      amount: 190,
      date: DateTime.now(),
      category: Category.work,
    ),
    Expense(
      title: 'Cinema',
      amount: 500,
      date: DateTime.now(),
      category: Category.leisure,
    ),
    Expense(
      title: 'Groceries',
      amount: 120,
      date: DateTime(2024, 6, 15),
      category: Category.food,
    ),
  ];

  bool _showPicker = false;
  String _currentMonth = _monthNames[DateTime.now().month - 1];

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  List<Expense> get _filteredExpenses {
    final selectedIndex = _monthNames.indexOf(_currentMonth) + 1;
    return _registeredExpenses.where((expense) {
      return expense.date.month == selectedIndex;
    }).toList();
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  void _removeExpense(Expense expense) {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense Deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _registeredExpenses.insert(expenseIndex, expense);
            });
          },
        ),
      ),
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Manager'),
        actions: [
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selected Month: $_currentMonth',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showPicker = !_showPicker;
                      });
                    },
                    child: const Text('Pick Month'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SavingTip(),
              Chart(expenses: _filteredExpenses),
              Expanded(
                child: _filteredExpenses.isEmpty
                    ? const Center(
                        child: Text('No expenses found for this month.'),
                      )
                    : ExpensesList(
                        expenses: _filteredExpenses,
                        onRemoveExpense: _removeExpense,
                      ),
              ),
            ],
          ),
          PickMonthOverlay(
            show: _showPicker,
            months: _monthNames,
            selectedMonth: _currentMonth,
            onMonthSelected: (month) {
              setState(() {
                _currentMonth = month;
                _showPicker = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
