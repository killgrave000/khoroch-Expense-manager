import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:khoroch/models/expense.dart';

/// Monthly insights:
/// - Header cards: total, avg/day, top category
/// - Optional overspend banner (vs category budgets)
/// - Category bar chart (budget markers)
/// - Daily cumulative line chart
class MonthlyInsightsScreen extends StatelessWidget {
  const MonthlyInsightsScreen({
    super.key,
    required this.expenses,
    this.categoryBudgets = const {},
    this.month,
  });

  final List<Expense> expenses;
  final Map<Category, double> categoryBudgets;
  final DateTime? month;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetMonth = month ?? DateTime(now.year, now.month);
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);

    final monthlyExpenses = expenses
        .where((e) =>
            e.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            e.date.isBefore(monthEnd.add(const Duration(days: 1))))
        .toList();

    final currency = NumberFormat.currency(symbol: "৳", decimalDigits: 0);

    // ---- Aggregations ----
    final total = monthlyExpenses.fold<double>(0.0, (s, e) => s + e.amount);
    final daysInMonth = monthEnd.day;
    final avgPerDay = daysInMonth > 0 ? total / daysInMonth : 0.0;

    final byCategory = <Category, double>{
      for (final c in Category.values) c: 0.0
    };
    for (final e in monthlyExpenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    // Top category
    Category? topCat;
    double topCatTotal = 0.0;
    byCategory.forEach((k, v) {
      if (v > topCatTotal) {
        topCat = k;
        topCatTotal = v;
      }
    });

    // Overspent vs budget
    final overspent = <Category, double>{};
    categoryBudgets.forEach((cat, budget) {
      final spent = byCategory[cat] ?? 0.0;
      if (spent > budget) overspent[cat] = spent - budget;
    });

    // Daily cumulative
    final dailyTotals = List<double>.filled(daysInMonth, 0.0);
    for (final e in monthlyExpenses) {
      final idx = e.date.day - 1;
      if (idx >= 0 && idx < daysInMonth) dailyTotals[idx] += e.amount;
    }
    final cumulative = <double>[];
    double running = 0.0;
    for (final v in dailyTotals) {
      running += v;
      cumulative.add(running);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Monthly Insights • ${DateFormat.yMMM().format(targetMonth)}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCards(
              totalText: currency.format(total),
              avgText: currency.format(avgPerDay),
              topCategoryText:
                  topCat == null ? "—" : "${_labelFor(topCat!)} (${currency.format(topCatTotal)})",
            ),
            const SizedBox(height: 12),

            if (overspent.isNotEmpty)
              _OverspendBanner(overspent: overspent, currency: currency),

            const SizedBox(height: 12),

            _SectionTitle("Spending by Category"),
            const SizedBox(height: 8),
            _CategoryBarChart(
              byCategory: byCategory,
              budgets: categoryBudgets,
              currency: currency,
            ),

            const SizedBox(height: 20),

            _SectionTitle("Daily Cumulative Spend"),
            const SizedBox(height: 8),
            _DailyCumulativeLineChart(
              cumulative: cumulative,
              currency: currency,
            ),

            const SizedBox(height: 8),
            _LegendNote(
              note:
                  "Tip: Smooth rise = consistent spending. Sharp jumps = big purchase days.",
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(Category c) {
    switch (c) {
      case Category.food:
        return "Food";
      case Category.leisure:
        return "Leisure";
      case Category.travel:
        return "Travel";
      case Category.work:
        return "Work";
      case Category.grocery:
        return "Grocery";
      case Category.bills:
        return "Bills";
    }
  }
}

/// -----------------------------
/// Header Cards
/// -----------------------------
class _HeaderCards extends StatelessWidget {
  const _HeaderCards({
    required this.totalText,
    required this.avgText,
    required this.topCategoryText,
  });

  final String totalText;
  final String avgText;
  final String topCategoryText;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(title: "Total Spent", value: totalText),
      _MetricCard(title: "Avg/Day", value: avgText),
      _MetricCard(title: "Top Category", value: topCategoryText),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1])]),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: cards[2])]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 8),
            Expanded(child: cards[1]),
            const SizedBox(width: 8),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------
/// Overspend Banner
/// -----------------------------
class _OverspendBanner extends StatelessWidget {
  const _OverspendBanner({required this.overspent, required this.currency});

  final Map<Category, double> overspent;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = overspent.entries
        .map((e) => "${_label(e.key)}: +${currency.format(e.value)}")
        .join(" • ");

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Overspent budget — $entries",
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(Category c) {
    switch (c) {
      case Category.food:
        return "Food";
      case Category.leisure:
        return "Leisure";
      case Category.travel:
        return "Travel";
      case Category.work:
        return "Work";
      case Category.grocery:
        return "Grocery";
      case Category.bills:
        return "Bills";
    }
  }
}

/// -----------------------------
/// Section Title + Note
/// -----------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _LegendNote extends StatelessWidget {
  const _LegendNote({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Text(
      note,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
    );
  }
}

/// -----------------------------
/// Category Bar Chart
/// -----------------------------
class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({
    required this.byCategory,
    required this.budgets,
    required this.currency,
  });

  final Map<Category, double> byCategory;
  final Map<Category, double> budgets;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final cats = Category.values;

    // Scale must consider both spending and budgets (so the budget marker is visible).
    double maxValue = 0;
    for (final c in cats) {
      maxValue = max(maxValue, byCategory[c] ?? 0);
      maxValue = max(maxValue, budgets[c] ?? 0);
    }
    final height = 260.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 18, 14),
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxValue <= 0 ? 100 : (maxValue * 1.2)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 42, // tighter for small screens
                    showTitles: true,
                    getTitlesWidget: (val, meta) => Text(
                      currency.format(val),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _label(cats[val.toInt()]),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),

              // IMPORTANT: Do NOT predeclare showingTooltipIndicators for all bars.
              // That caused all the tooltips + vertical lines to show at once.
              barGroups: List.generate(cats.length, (i) {
                final cat = cats[i];
                final spent = byCategory[cat] ?? 0.0;
                final budget = budgets[cat];
                final isOver = (budget != null && spent > budget);

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: spent,
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                      color: isOver
                          ? Colors.redAccent
                          : Theme.of(context).colorScheme.primary,
                    ),
                    if (budget != null)
                      BarChartRodData(
                        toY: budget,
                        width: 6,
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey.shade500,
                      ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipMargin: 6,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final cat = cats[group.x];
                    final isBudgetRod = (rod.width == 6);
                    final title = isBudgetRod ? "Budget" : "Spent";
                    return BarTooltipItem(
                      "${_label(cat)}\n$title: ${currency.format(rod.toY)}",
                      const TextStyle(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _label(Category c) {
    switch (c) {
      case Category.food:
        return "Food";
      case Category.leisure:
        return "Leisure";
      case Category.travel:
        return "Travel";
      case Category.work:
        return "Work";
      case Category.grocery:
        return "Grocery";
      case Category.bills:
        return "Bills";
    }
  }
}

/// -----------------------------
/// Daily Cumulative Line Chart
/// -----------------------------
class _DailyCumulativeLineChart extends StatelessWidget {
  const _DailyCumulativeLineChart({
    required this.cumulative,
    required this.currency,
  });

  final List<double> cumulative;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final maxY = cumulative.isEmpty ? 100.0 : (cumulative.last * 1.1);
    final spots = <FlSpot>[
      for (int i = 0; i < cumulative.length; i++) FlSpot((i + 1).toDouble(), cumulative[i]),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 18, 14),
        child: SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: cumulative.isEmpty ? 31 : cumulative.length.toDouble(),
              minY: 0,
              maxY: maxY <= 0 ? 100.0 : maxY,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 48,
                    showTitles: true,
                    getTitlesWidget: (v, m) =>
                        Text(currency.format(v), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 26,
                    showTitles: true,
                    interval: (cumulative.length / 6).clamp(1, 6).toDouble(),
                    getTitlesWidget: (v, m) =>
                        Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final day = s.x.toInt();
                    final val = currency.format(s.y);
                    return LineTooltipItem("Day $day\n$val",
                        const TextStyle(fontWeight: FontWeight.w600));
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
