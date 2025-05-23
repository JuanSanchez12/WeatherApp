import 'package:flutter/material.dart';
import '../Services/weather_service.dart';
import '../Services/city_search_delegate.dart';
import '../Providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

/// Screen that displays a 7-day weather forecast with detailed daily information
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData; // Stores complete weather data from API
  bool _isLoading = false; // Tracks loading state
  String _error = ''; // Stores error messages
  int _selectedDayIndex = 0; // Tracks which day is selected in the forecast

  // Maps weather conditions to background colors
  final Map<String, Color> _weatherColors = {
    'clear': Colors.orange[100]!,
    'clouds': Colors.grey[200]!,
    'rain': Colors.blue[100]!,
    'snow': Colors.blue[50]!,
    'thunderstorm': Colors.purple[100]!,
    'default': Colors.red[100]!,
  };

  // Maps weather conditions to display icons
  final Map<String, IconData> _weatherIcons = {
    'clear': Icons.wb_sunny,
    'clouds': Icons.cloud,
    'rain': Icons.beach_access,
    'snow': Icons.ac_unit,
    'thunderstorm': Icons.flash_on,
  };

  /// Returns appropriate icon color based on weather condition
  Color _getWeatherIconColor(String weatherType) {
    switch (weatherType) {
      case 'clear': return Colors.orange;
      case 'clouds': return Colors.grey;
      case 'rain': return Colors.blue;
      case 'snow': return Colors.lightBlue;
      case 'thunderstorm': return Colors.deepPurple;
      default: return Colors.black;
    }
  }

  /// Fetches weather data for given coordinates
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

  /// Shows city search dialog and updates location when selected
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
        
        // Update app-wide location
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.updateLocation(
          selectedCity,
          LatLng(location['lat'], location['lon']),
        );
        
        // Fetch weather for new location
        _fetchWeather(location['lat'], location['lon']);
      }
    }
  }

  /// Determines background color based on current weather
  Color _getBackgroundColor() {
    if (_weatherData == null) return _weatherColors['default']!;
    final condition = _weatherData!['current']['weather'][0]['main'].toString().toLowerCase();
    return _weatherColors[condition] ?? _weatherColors['default']!;
  }

  @override
  void initState() {
    super.initState();
    // Fetch weather for current location after first frame
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
    final weatherCondition = _weatherData?['current']['weather'][0]['main']?.toString().toLowerCase() ?? 'clear';
    final iconColor = _getWeatherIconColor(weatherCondition);

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: const Text('7-Day Forecast'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
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
                      // Current weather summary card
                      _buildCurrentWeatherCard(locationProvider.currentCity, weatherCondition, iconColor),
                      const SizedBox(height: 20),
                      // Horizontal list of forecast days
                      _buildDailyForecastList(),
                      const SizedBox(height: 20),
                      // Detailed card for selected day
                      if (_weatherData != null && _weatherData!['daily'] != null)
                        _buildSelectedDayCard(_weatherData!['daily'][_selectedDayIndex]),
                    ],
                  ),
                ),
    );
  }

  /// Builds the current weather summary card
  Widget _buildCurrentWeatherCard(String locationName, String weatherCondition, Color iconColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Weather condition icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _weatherColors[weatherCondition] ?? _weatherColors['default']!,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _weatherIcons[weatherCondition] ?? Icons.help_outline,
                    color: iconColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 10),
                // Location name
                Text(
                  locationName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Current temperature
            Text(
              '${_weatherData?['current']['temp']?.toStringAsFixed(1) ?? '--'}°F',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Weather description
            Text(
              _weatherData?['current']['weather'][0]['main']?.toString() ?? '--',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            // Weather details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail(Icons.water_drop, 'Humidity', '${_weatherData?['current']['humidity']?.toString() ?? '--'}%'),
                _buildWeatherDetail(Icons.air, 'Wind', '${_weatherData?['current']['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                _buildWeatherDetail(Icons.umbrella, 'Precip', '${_weatherData?['current']['rain']?['1h']?.toStringAsFixed(0) ?? '0'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal scrollable list of forecast days
  Widget _buildDailyForecastList() {
    if (_weatherData == null || _weatherData!['daily'] == null) {
      return const Center(child: Text('No forecast data available'));
    }

    final dailyForecast = _weatherData!['daily'] as List<dynamic>;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dailyForecast.length,
        itemBuilder: (context, index) {
          final day = dailyForecast[index];
          final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
          final dayName = _getDayName(date.weekday);
          final isSelected = _selectedDayIndex == index;
          final weatherCondition = day['weather'][0]['main'].toString().toLowerCase();
          final iconColor = _getWeatherIconColor(weatherCondition);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day name
                  Text(
                    dayName.substring(0, 3),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Weather icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _weatherColors[weatherCondition] ?? _weatherColors['default']!,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _weatherIcons[weatherCondition] ?? Icons.help_outline,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Temperature range
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

  /// Builds detailed card for the selected day
  Widget _buildSelectedDayCard(Map<String, dynamic> day) {
    final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
    final dayName = _getDayName(date.weekday);
    final weatherCondition = day['weather'][0]['main'].toString().toLowerCase();
    final iconColor = _getWeatherIconColor(weatherCondition);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Weather icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _weatherColors[weatherCondition] ?? _weatherColors['default']!,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _weatherIcons[weatherCondition] ?? Icons.help_outline,
                    color: iconColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 10),
                // Date information
                Text(
                  '$dayName, ${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Weather description
            Text(
              weatherCondition,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            // First row of details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail(Icons.arrow_upward, 'High', '${day['temp']['max']?.toStringAsFixed(0) ?? '--'}°F'),
                _buildWeatherDetail(Icons.arrow_downward, 'Low', '${day['temp']['min']?.toStringAsFixed(0) ?? '--'}°F'),
                _buildWeatherDetail(Icons.water_drop, 'Humidity', '${day['humidity']}%'),
              ],
            ),
            const SizedBox(height: 16),
            // Second row of details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail(Icons.wb_sunny, 'Sunrise', _formatTime(day['sunrise'])),
                _buildWeatherDetail(Icons.nightlight, 'Sunset', _formatTime(day['sunset'])),
                _buildWeatherDetail(Icons.umbrella, 'Precip', '${(day['pop'] * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build consistent weather detail items
  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Converts weekday number to day name
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

  /// Formats timestamp into HH:MM time string
  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}