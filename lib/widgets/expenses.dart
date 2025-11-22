import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/widgets/chart/chart.dart';
import 'package:khoroch/widgets/expenses_list/expenses_list.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/widgets/new_expense.dart';
import 'package:khoroch/widgets/saving_tip.dart';
import 'package:khoroch/widgets/home/pick_date_overlay.dart';
import 'package:khoroch/widgets/home/sidebar_drawer.dart';
import 'package:khoroch/database/database_helper.dart';
import 'package:flutter/rendering.dart';

// ----------------------
// FILTER ENUM
// ----------------------
enum Filter { daily, weekly, monthly }

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Expense> _registeredExpenses = [];
  bool _showPicker = false;
  DateTime _selectedDate = DateTime.now();

  Filter selectedFilter = Filter.daily;

  // NEW: Scroll controller + chart visibility
  late ScrollController _scrollController;
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showChart) setState(() => _showChart = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showChart) setState(() => _showChart = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    setState(() {
      _registeredExpenses = expenses;
    });
  }

  // ----------------------
  // FILTERING LOGIC
  // ----------------------
  List<Expense> get _filteredExpenses {
    final now = _selectedDate;

    return _registeredExpenses.where((expense) {
      if (selectedFilter == Filter.daily) {
        return expense.date.year == now.year &&
            expense.date.month == now.month &&
            expense.date.day == now.day;
      }

      if (selectedFilter == Filter.weekly) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return expense.date.isAfter(startOfWeek);
      }

      if (selectedFilter == Filter.monthly) {
        return expense.date.year == now.year &&
            expense.date.month == now.month;
      }

      return false;
    }).toList();
  }

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
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 88),
            child: Column(
              children: [
                // DATE ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selected: $formattedDate',
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

                // ----------------------------
                // FILTER BUTTONS WITH ANIMATION
                // ----------------------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: SegmentedButton<Filter>(
                    segments: const [
                      ButtonSegment(
                        value: Filter.daily,
                        label: Text('Daily'),
                      ),
                      ButtonSegment(
                        value: Filter.weekly,
                        label: Text('Weekly'),
                      ),
                      ButtonSegment(
                        value: Filter.monthly,
                        label: Text('Monthly'),
                      ),
                    ],
                    selected: {selectedFilter},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        selectedFilter = newSelection.first;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),

                SavingTip(),

                // ----------------------------
                // CHART THAT HIDES WHEN SCROLLING
                // ----------------------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _showChart ? 220 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showChart ? 1 : 0,
                    child: Chart(
                      key: ValueKey(
                        selectedFilter.toString() + _selectedDate.toString(),
                      ),
                      expenses: _filteredExpenses,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------
                // ANIMATED EXPENSE LIST
                // ----------------------------
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _filteredExpenses.isEmpty
                        ? const Center(
                            key: ValueKey('empty'),
                            child: Text('No expenses found.'),
                          )
                        : ExpensesList(
                            key: ValueKey(
                              selectedFilter.toString() +
                                  _selectedDate.toString(),
                            ),
                            controller: _scrollController, // IMPORTANT
                            expenses: _filteredExpenses,
                            onRemoveExpense: _removeExpense,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // DATE PICKER OVERLAY
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpensePage,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
        heroTag: 'add_expense_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
