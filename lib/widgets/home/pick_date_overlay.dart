import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickDateOverlay extends StatelessWidget {
  final bool show;
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  const PickDateOverlay({
    Key? key,
    required this.show,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int selectedMonthIndex = selectedDate.month;
    final int selectedYear = selectedDate.year;
    final int selectedDay = selectedDate.day;

    final int daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonthIndex);

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month Selector
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(12, (index) {
                  final isSelected = index + 1 == selectedMonthIndex;
                  return ChoiceChip(
                    label: Text(_monthNames[index]),
                    selected: isSelected,
                    onSelected: (_) {
                      final updated = DateTime(selectedYear, index + 1, selectedDay);
                      onDateSelected(updated);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Day Picker
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () {
                      final updated = DateTime(selectedYear, selectedMonthIndex, day);
                      onDateSelected(updated);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyLarge!.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
