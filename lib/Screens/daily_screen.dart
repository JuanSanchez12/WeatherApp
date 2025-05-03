import 'package:flutter/material.dart';
import '../Services/weather_service.dart';
import '../Services/city_search_delegate.dart';
import '../Providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String _error = '';
  int _selectedDayIndex = 0;

  final Map<String, Color> _weatherColors = {
    'clear': Colors.orange[100]!,
    'clouds': Colors.grey[200]!,
    'rain': Colors.blue[100]!,
    'snow': Colors.blue[50]!,
    'thunderstorm': Colors.purple[100]!,
    'default': Colors.red[100]!,
  };

  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final weatherData = await _weatherService.getWeather(lat, lon);
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather data';
        _isLoading = false;
      });
    }
  }

  Future<void> _showSearch(BuildContext context) async {
    final selectedCity = await showSearch<String>(
      context: context,
      delegate: CitySearchDelegate(_weatherService),
    );

    if (selectedCity != null && selectedCity.isNotEmpty) {
      final cities = await _weatherService.searchCities(selectedCity.split(',')[0]);
      if (cities.isNotEmpty) {
        final location = cities.firstWhere(
          (c) => '${c['name']}${c['state'] != null ? ', ${c['state']}' : ''}, ${c['country']}' == selectedCity,
          orElse: () => cities.first,
        );
        
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.updateLocation(
          selectedCity,
          LatLng(location['lat'], location['lon']),
        );
        
        _fetchWeather(location['lat'], location['lon']);
      }
    }
  }

  Color _getBackgroundColor() {
    if (_weatherData == null) return _weatherColors['default']!;
    final condition = _weatherData!['current']['weather'][0]['main'].toString().toLowerCase();
    return _weatherColors[condition] ?? _weatherColors['default']!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _fetchWeather(
        locationProvider.currentLatLng.latitude,
        locationProvider.currentLatLng.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: const Text('7-Day Forecast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Current Weather Card
                      _buildCurrentWeatherCard(locationProvider.currentCity),
                      const SizedBox(height: 20),
                      // Horizontal Daily Forecast
                      _buildDailyForecastList(),
                      const SizedBox(height: 20),
                      // Selected Day Details Card
                      if (_weatherData != null && _weatherData!['daily'] != null)
                        _buildSelectedDayCard(_weatherData!['daily'][_selectedDayIndex]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentWeatherCard(String locationName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              locationName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${_weatherData?['current']['temp']?.toStringAsFixed(1) ?? '--'}°F',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _weatherData?['current']['weather'][0]['main']?.toString() ?? '--',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail('Humidity', '${_weatherData?['current']['humidity']?.toString() ?? '--'}%'),
                _buildWeatherDetail('Wind', '${_weatherData?['current']['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                _buildWeatherDetail('Precip', '${_weatherData?['current']['rain']?['1h']?.toStringAsFixed(0) ?? '0'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecastList() {
    if (_weatherData == null || _weatherData!['daily'] == null) {
      return const Center(child: Text('No forecast data available'));
    }

    final dailyForecast = _weatherData!['daily'] as List<dynamic>;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dailyForecast.length,
        itemBuilder: (context, index) {
          final day = dailyForecast[index];
          final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
          final dayName = _getDayName(date.weekday);
          final isSelected = _selectedDayIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.substring(0, 3),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day['temp']['max']?.toStringAsFixed(0) ?? '--'}°',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${day['temp']['min']?.toStringAsFixed(0) ?? '--'}°',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayCard(Map<String, dynamic> day) {
    final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
    final dayName = _getDayName(date.weekday);
    final weatherCondition = day['weather'][0]['main'].toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$dayName, ${date.month}/${date.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              weatherCondition,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail('High', '${day['temp']['max']?.toStringAsFixed(0) ?? '--'}°F'),
                _buildWeatherDetail('Low', '${day['temp']['min']?.toStringAsFixed(0) ?? '--'}°F'),
                _buildWeatherDetail('Humidity', '${day['humidity']}%'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail('Sunrise', _formatTime(day['sunrise'])),
                _buildWeatherDetail('Sunset', _formatTime(day['sunset'])),
                _buildWeatherDetail('Precip', '${(day['pop'] * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}