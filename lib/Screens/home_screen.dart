import 'package:flutter/material.dart';
import '../Services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _temperature;
  bool _isLoading = true;
  String _error = '';

  Future<void> _getWeather() async {
    try {
      final temp = await WeatherService().getAtlantaTemperature();
      setState(() {
        _temperature = temp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Atlanta Weather',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : _error.isNotEmpty
                    ? Text(_error, style: const TextStyle(color: Colors.red))
                    : Text(
                        '${_temperature?.toStringAsFixed(1)}°F',
                        style: const TextStyle(fontSize: 48),
                      ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getWeather,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}