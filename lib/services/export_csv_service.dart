import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:khoroch/database/database_helper.dart';
import 'package:khoroch/models/expense.dart';

class ExportCsvService {
  /// Builds CSV from your DB, writes it into the app's documents folder,
  /// and (optionally) opens the system share sheet.
  static Future<String> exportExpensesHistoryCsv({bool shareAfter = true}) async {
    // 1) Load data (adjust to your own DB call if different)
    final List<Expense> expenses = await DatabaseHelper.instance.getAllExpenses();

    // 2) Generate CSV (simple example: date,title,category,amount)
    final buf = StringBuffer();
    buf.writeln("date,title,category,amount");
    final dateFmt = DateFormat('yyyy-MM-dd');
    for (final e in expenses) {
      final date = dateFmt.format(e.date);
      final title = _escapeCsv(e.title);
      final category = e.category.name;
      final amount = e.amount.toStringAsFixed(2);
      buf.writeln('$date,$title,$category,$amount');
    }
    final csv = buf.toString();

    // 3) Write file in app documents (permission-free)
    final dir = await getApplicationDocumentsDirectory(); // e.g., /data/user/0/<pkg>/files
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/khoroch_expenses_$ts.csv');
    await file.writeAsString(csv);

    // 4) Optionally open share sheet so user can save/send it anywhere
    if (shareAfter) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: 'khoroch_expenses_$ts.csv')],
        subject: 'Khoroch – Expenses CSV ($ts)',
        text: 'Exported from Khoroch.',
      );
    }

    return file.path;
  }

  static String _escapeCsv(String input) {
    // Escape quotes and wrap if needed
    final needWrap = input.contains(',') || input.contains('"') || input.contains('\n');
    final escaped = input.replaceAll('"', '""');
    return needWrap ? '"$escaped"' : escaped;
  }
}
