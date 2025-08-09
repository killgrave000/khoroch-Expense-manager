import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/widgets/chart/chart.dart';
import 'package:khoroch/widgets/expenses_list/expenses_list.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/widgets/new_expense.dart';
import 'package:khoroch/widgets/saving_tip.dart';
import 'package:khoroch/widgets/home/pick_date_overlay.dart';
import 'package:khoroch/widgets/home/sidebar_drawer.dart';
import 'package:khoroch/database/database_helper.dart'; // ✅ DB Helper import

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Expense> _registeredExpenses = [];
  bool _showPicker = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    setState(() {
      _registeredExpenses = expenses;
    });
  }

  List<Expense> get _filteredExpenses {
    return _registeredExpenses.where((expense) {
      return expense.date.year == _selectedDate.year &&
          expense.date.month == _selectedDate.month &&
          expense.date.day == _selectedDate.day;
    }).toList();
  }

  // ⬇️ Open NewExpense as a full-screen page (so keyboard never hides it)
  void _openAddExpensePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewExpense(onAddExpense: _addExpense),
      ),
    );
  }

  Future<void> _addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    await _loadExpenses();
  }

  Future<void> _removeExpense(Expense expense) async {
    await DatabaseHelper.instance.deleteExpense(expense.id);
    await _loadExpenses();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense Deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await DatabaseHelper.instance.insertExpense(expense);
            await _loadExpenses();
          },
        ),
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);

    return Scaffold(
      drawer: SidebarDrawer(
        onLogout: _logout,
        expenses: _registeredExpenses,
      ),
      appBar: AppBar(
        title: const Text('Expense Manager'),
        actions: [
          IconButton(
            onPressed: _openAddExpensePage, // ⬅️ use the full-screen opener
            icon: const Icon(Icons.add),
            tooltip: 'Add Expense',
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
                    'Selected Date: $formattedDate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showPicker = !_showPicker;
                      });
                    },
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
               SavingTip(),
              Chart(expenses: _filteredExpenses),
              Expanded(
                child: _filteredExpenses.isEmpty
                    ? const Center(
                        child: Text('No expenses found for this date.'),
                      )
                    : ExpensesList(
                        expenses: _filteredExpenses,
                        onRemoveExpense: _removeExpense,
                      ),
              ),
            ],
          ),
          PickDateOverlay(
            show: _showPicker,
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                _showPicker = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
