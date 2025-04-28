import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100], // Light green background
      child: const Center(
        child: Text('Community Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}