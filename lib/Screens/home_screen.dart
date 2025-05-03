import 'package:flutter/material.dart';
import '../Services/weather_service.dart';
import '../Services/city_search_delegate.dart';
import '../Providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

/// HomeScreen displays current weather and hourly forecast for a location
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _currentWeather; // Stores current weather data
  List<dynamic> _hourlyForecast = []; // Stores hourly forecast data
  bool _isLoading = false; // Loading state flag
  String _error = ''; // Error message storage
  int? _expandedHourIndex; // Tracks which hourly forecast item is expanded

  /// Maps weather conditions to background colors
  final Map<String, Color> _weatherColors = {
    'clear': Colors.orange[100]!,
    'clouds': Colors.grey[200]!,
    'rain': Colors.blue[100]!,
    'snow': Colors.blue[50]!,
    'thunderstorm': Colors.purple[100]!,
    'default': Colors.red[100]!,
  };

  /// Maps weather conditions to display icons
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

  /// Fetches weather data for given coordinates and updates state
  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _expandedHourIndex = null;
    });

    try {
      final weatherData = await _weatherService.getWeather(lat, lon);
      setState(() {
        _currentWeather = weatherData['current'];
        _hourlyForecast = weatherData['hourly'].sublist(0, 12); // Next 12 hours
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get weather data';
        _isLoading = false;
      });
    }
  }

  /// Shows city search dialog and handles location selection
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
        
        // Update app-wide location state
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
    if (_currentWeather == null) return _weatherColors['default']!;
    final condition = _currentWeather!['weather'][0]['main'].toString().toLowerCase();
    return _weatherColors[condition] ?? _weatherColors['default']!;
  }

  @override
  void initState() {
    super.initState();
    // Fetch weather for current location after first frame renders
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
    final weatherCondition = _currentWeather?['weather'][0]['main']?.toString().toLowerCase() ?? 'clear';
    final iconColor = _getWeatherIconColor(weatherCondition);

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: const Text('Weather Dashboard'),
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
                      _buildCurrentWeatherCard(locationProvider.currentCity, weatherCondition, iconColor),
                      const SizedBox(height: 20),
                      _buildHourlyForecast(iconColor),
                    ],
                  ),
                ),
    );
  }

  /// Builds the card displaying current weather conditions
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
                Text(
                  locationName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_currentWeather?['temp']?.toStringAsFixed(1) ?? '--'}°F',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _currentWeather?['weather'][0]['main']?.toString() ?? '--',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail(Icons.water_drop, 'Humidity', '${_currentWeather?['humidity']?.toString() ?? '--'}%'),
                _buildWeatherDetail(Icons.air, 'Wind', '${_currentWeather?['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                _buildWeatherDetail(Icons.umbrella, 'Precip', '${_currentWeather?['rain']?['1h']?.toStringAsFixed(0) ?? '0'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a weather detail item (icon + value)
  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Builds the hourly forecast list with expandable items
  Widget _buildHourlyForecast(Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hourly Forecast',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _hourlyForecast.length,
          itemBuilder: (context, index) {
            final hour = _hourlyForecast[index];
            final time = DateTime.fromMillisecondsSinceEpoch(hour['dt'] * 1000);
            final isExpanded = _expandedHourIndex == index;
            final precip = hour['rain']?['1h']?.toStringAsFixed(0) ?? '0';
            final weatherCondition = hour['weather'][0]['main'].toString().toLowerCase();
            final hourIconColor = _getWeatherIconColor(weatherCondition);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white.withOpacity(0.8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedHourIndex = isExpanded ? null : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${time.hour}:00',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _weatherColors[weatherCondition] ?? _weatherColors['default']!,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _weatherIcons[weatherCondition] ?? Icons.help_outline,
                              color: hourIconColor,
                              size: 20,
                            ),
                          ),
                          Text('${hour['temp']?.toStringAsFixed(0) ?? '--'}°F'),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildWeatherDetail(Icons.water_drop, 'Humidity', '${hour['humidity']?.toString() ?? '--'}%'),
                              _buildWeatherDetail(Icons.air, 'Wind', '${hour['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                              _buildWeatherDetail(Icons.umbrella, 'Precip', '$precip%'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}