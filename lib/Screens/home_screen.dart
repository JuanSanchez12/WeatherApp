import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[100], // Light red background
      child: const Center(
        child: Text('Home Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}