import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Date')),
      body: Center(
        child: ElevatedButton(
          child: const Text("Continue to Expenses"),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/expenses');
          },
        ),
      ),
    );
  }
}
