import 'package:flutter/material.dart';
import '../Services/weather_service.dart';
import '../Services/city_search_delegate.dart';
import '../Providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _currentWeather;
  List<dynamic> _hourlyForecast = [];
  bool _isLoading = false;
  String _error = '';
  int? _expandedHourIndex;

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
    if (_currentWeather == null) return _weatherColors['default']!;
    final condition = _currentWeather!['weather'][0]['main'].toString().toLowerCase();
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
        title: const Text('Weather Dashboard'),
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
                      // Hourly Forecast
                      _buildHourlyForecast(),
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
                _buildWeatherDetail('Humidity', '${_currentWeather?['humidity']?.toString() ?? '--'}%'),
                _buildWeatherDetail('Wind', '${_currentWeather?['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                _buildWeatherDetail('Precip', '${_currentWeather?['rain']?['1h']?.toStringAsFixed(0) ?? '0'}%'),
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

  Widget _buildHourlyForecast() {
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
            final weatherCondition = hour['weather'][0]['main'].toString();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
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
                          Text(
                            weatherCondition,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                              _buildWeatherDetail('Humidity', '${hour['humidity']?.toString() ?? '--'}%'),
                              _buildWeatherDetail('Wind', '${hour['wind_speed']?.toStringAsFixed(1) ?? '--'} mph'),
                              _buildWeatherDetail('Precip', '$precip%'),
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