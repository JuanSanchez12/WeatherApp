import 'package:flutter/material.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple[100], // Light purple background
      child: const Center(
        child: Text('Radar Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}