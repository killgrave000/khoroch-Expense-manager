import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:khoroch/database/database_helper.dart';
import 'package:khoroch/models/budget.dart';

class MonthBudgetExportService {
  /// Loads budgets for the given month and returns a normalized JSON string.
  /// month is normalized to first day (YYYY-MM-01).
  static Future<String> buildMonthBudgetJson(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    final items = await DatabaseHelper.instance.getBudgetsForMonth(normalized);

    // Build a simple map: {"food": 8000, "work": 7000, ...}
    final budgets = <String, double>{};
    for (final b in items) {
      budgets[b.category.name] = b.amount;
    }

    final total = budgets.values.fold<double>(0, (s, v) => s + v);
    final payload = {
      "month": DateFormat('yyyy-MM').format(normalized),
      "currency": "BDT",
      "budgets": budgets, // {categoryName: amount}
      "total": total,
      "exported_at": DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
      "source": "khoroch"
    };

    // Pretty JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  /// Writes the JSON into the app's documents dir and optionally opens the Share sheet.
  /// Returns the saved file path.
  static Future<String> saveAndShareMonthBudgetJson({
    required DateTime month,
    bool shareAfter = true,
  }) async {
    final jsonString = await buildMonthBudgetJson(month);

    final dir = await getApplicationDocumentsDirectory();
    final yyyymm = DateFormat('yyyyMM').format(DateTime(month.year, month.month));
    final filename = 'khoroch_month_budget_$yyyymm.json';
    final file = File('${dir.path}/$filename');

    await file.writeAsString(jsonString);

    if (shareAfter) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: filename)],
        subject: 'Khoroch – Monthly Budget ($yyyymm)',
        text: 'Monthly budget export from Khoroch.',
      );
    }
    return file.path;
  }
}
