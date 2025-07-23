import 'package:flutter/material.dart';

class PickMonthOverlay extends StatelessWidget {
  final bool show;
  final List<String> months;
  final String selectedMonth;
  final void Function(String) onMonthSelected;

  const PickMonthOverlay({
    Key? key,
    required this.show,
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        color: Colors.transparent, // make background blend with theme
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: 6,
            children: months.map((month) {
              final isSelected = month == selectedMonth;
              return InkWell(
                onTap: () => onMonthSelected(month),
                borderRadius: BorderRadius.circular(4),
                child: Center(
                  child: Text(
                    month,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge!.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
