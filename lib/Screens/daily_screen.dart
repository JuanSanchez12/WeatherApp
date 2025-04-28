import 'package:flutter/material.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[100], // Light blue background
      child: const Center(
        child: Text('Daily Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}