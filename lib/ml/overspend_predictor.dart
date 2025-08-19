import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show DateUtils;


class OverspendPredictor {
  late Interpreter _interpreter;
  late List<String> _featureOrder;
  late List<double> _mean;
  late List<double> _std;

  // Categories must match training CATS
  static const List<String> CATS = ["food","grocery","leisure","travel","work","bills"];

  OverspendPredictor._();

  static Future<OverspendPredictor> load() async {
    final p = OverspendPredictor._();
    // Load meta
    final metaStr = await rootBundle.loadString('assets/ml/overspend_meta.json');
    final meta = json.decode(metaStr) as Map<String, dynamic>;
    p._featureOrder = (meta['feature_order'] as List).map((e) => e.toString()).toList();
    p._mean = (meta['mean'] as List).map((e) => (e as num).toDouble()).toList();
    p._std  = (meta['std']  as List).map((e) => (e as num).toDouble()).toList();

    // Load model
    p._interpreter = await Interpreter.fromAsset('assets/ml/overspend.tflite');
    return p;
  }

  /// expenses: list of maps {title, amount(double), date(DateTime), category(lowercase)}
  /// budgets:  map<String,double> same keys as CATS
  /// snapshotDay: usually DateTime.now().day for "today so far"
  double predictProbability({
    required List<Map<String, dynamic>> expenses,
    required Map<String, double> budgets,
    required DateTime month,
    int? snapshotDay,
    double smallPurchaseThreshold = 300.0,
  }) {
    if (expenses.isEmpty) return 0.0;

    final monthStr = DateFormat('yyyy-MM').format(month);
    final monthExps = expenses.where((e) {
      final d = e['date'] as DateTime;
      return DateFormat('yyyy-MM').format(d) == monthStr;
    }).toList();

    if (monthExps.isEmpty) return 0.0;

    monthExps.sort((a,b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final day = (snapshotDay ?? DateTime.now().day).clamp(1, daysInMonth);
    final mtd = monthExps.where((e) => (e['date'] as DateTime).day <= day).toList();

    if (mtd.isEmpty) return 0.0;

    // --- features (must mirror Python) ---
    final spendMtd = mtd.fold<double>(0.0, (s,e) => s + (e['amount'] as num).toDouble());
    final daysRatio = day / daysInMonth;
    final avgDaily = spendMtd / (day > 0 ? day : 1);

    final last7Start = (day - 6) < 1 ? 1 : (day - 6);
    final last7 = mtd.where((e) {
      final d = (e['date'] as DateTime).day;
      return d >= last7Start && d <= day;
    }).fold<double>(0.0, (s,e) => s + (e['amount'] as num).toDouble());
    final baseline = (spendMtd / (day > 0 ? day : 1)) * 7.0;
    final last7VsBase = last7 / (baseline > 0 ? baseline : 1e-6);

    final smallCnt = mtd.where((e) => (e['amount'] as num).toDouble() <= smallPurchaseThreshold).length;

    // recurring_count: titles that appear >=3 times this month-to-date (normalized)
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    final titles = mtd.map((e) => norm(e['title'] as String)).toList();
    final counts = <String,int>{};
    for (final t in titles) { counts[t] = (counts[t] ?? 0) + 1; }
    final recurringKeys = counts.entries.where((kv) => kv.value >= 3).map((kv) => kv.key).toSet();
    final recurringCnt = titles.where(recurringKeys.contains).length;

    final catSums = <String,double>{ for (final c in CATS) c: 0.0 };
    for (final e in mtd) {
      final c = (e['category'] as String).toLowerCase();
      if (catSums.containsKey(c)) {
        catSums[c] = catSums[c]! + (e['amount'] as num).toDouble();
      }
    }

    final totalBudget = CATS.fold<double>(0.0, (s,c) => s + (budgets[c] ?? 0.0));
    final budgetGapTotal = totalBudget - spendMtd;

    // build feature dict aligned with Python
    final feat = <String,double>{
      "days_ratio": daysRatio,
      "spend_mtd": spendMtd,
      "avg_daily": avgDaily,
      "last7_sum": last7,
      "last7_vs_base": last7VsBase,
      "small_cnt": smallCnt.toDouble(),
      "recurring_cnt": recurringCnt.toDouble(),
      "budget_gap_total": budgetGapTotal,
      // category features
      for (final c in CATS) ...{
        "${c}_mtd": catSums[c] ?? 0.0,
        "${c}_ratio": spendMtd > 0 ? ( (catSums[c] ?? 0.0) / spendMtd ) : 0.0,
      }
    };

    // vectorize in the exact order from meta
    final x = _featureOrder.map((k) => (feat[k] ?? 0.0)).toList();

    // scale: (x - mean)/std
    final scaled = List<double>.generate(x.length, (i) {
      final denom = (_std[i] != 0.0) ? _std[i] : 1e-6;
      return (x[i] - _mean[i]) / denom;
    });

    // run tflite
    final input = [scaled];
    final output = List.filled(1, List.filled(1, 0.0));
    _interpreter.run(input, output);
    final prob = (output[0][0] as double);
    return prob.clamp(0.0, 1.0);
  }

  void close() {
    _interpreter.close();
  }
}
