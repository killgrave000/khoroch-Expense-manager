import 'package:shared_preferences/shared_preferences.dart';

class BudgetAlertGuard {
  /// Returns true if we should show an alert now (not shown before this month).
  static Future<bool> shouldNotify({
    required String categoryKey,
    required DateTime month, // use DateTime(year, month)
    required String type, // 'approach' or 'exceeded'
  }) async {
    final m = DateTime(month.year, month.month);
    final prefs = await SharedPreferences.getInstance();
    final key = 'notified_${type}_${categoryKey}_${m.year}_${m.month}';
    final seen = prefs.getBool(key) ?? false;
    if (!seen) {
      await prefs.setBool(key, true);
      return true;
    }
    return false;
  }

  /// Reset a flag (optional utility if you need to test repeatedly).
  static Future<void> clear({
    required String categoryKey,
    required DateTime month,
    required String type,
  }) async {
    final m = DateTime(month.year, month.month);
    final prefs = await SharedPreferences.getInstance();
    final key = 'notified_${type}_${categoryKey}_${m.year}_${m.month}';
    await prefs.remove(key);
  }
}
