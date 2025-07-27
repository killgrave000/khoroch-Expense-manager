enum BudgetCategory { food, leisure, travel, work, grocery, bills }

class Budget {
  final BudgetCategory category;
  double amount;

  Budget({required this.category, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'amount': amount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: BudgetCategory.values.firstWhere((c) => c.name == map['category']),
      amount: map['amount'],
    );
  }
}
