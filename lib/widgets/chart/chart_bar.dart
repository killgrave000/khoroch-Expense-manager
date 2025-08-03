import 'package:flutter/material.dart';

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.fill,
    this.isOverspent = false,
  });

  final double fill;
  final bool isOverspent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (isOverspent)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '⚠ High',
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ),
          Expanded(
            child: FractionallySizedBox(
              heightFactor: fill,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  color: isOverspent
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
