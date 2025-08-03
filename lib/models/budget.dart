enum BudgetCategory { food, leisure, travel, work, grocery, bills }

class Budget {
  final BudgetCategory category;
  double amount;
  final DateTime month; // ✅ New field

  Budget({
    required this.category,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'amount': amount,
      'month': month.toIso8601String(), // ✅ Store as ISO string
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: BudgetCategory.values.firstWhere((c) => c.name == map['category']),
      amount: map['amount'],
      month: DateTime.parse(map['month']), // ✅ Parse string to DateTime
    );
  }
}
