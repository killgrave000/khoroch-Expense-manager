import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return await openDatabase(
      path,
      version: 2, // ✅ increment when schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        date TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        amount REAL,
        month TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE budgets ADD COLUMN month TEXT');
    }
  }

  // ────────────────────────────────────────────────────────────
  // EXPENSE METHODS

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getMatchingExpenseSuggestions(String input) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'LOWER(title) LIKE ?',
      whereArgs: ['%${input.toLowerCase()}%'],
      orderBy: 'date DESC',
      limit: 5,
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // BUDGET METHODS

  Future<void> insertOrUpdateBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getBudgetsForMonth(DateTime month) async {
    final db = await database;

    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final maps = await db.query(
      'budgets',
      where: 'month >= ? AND month < ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    return maps.map((map) => Budget.fromMap(map)).toList();
  }
}
