import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Services/weather_service.dart';
import '../Services/city_search_delegate.dart';
import '../Providers/location_provider.dart';
import 'package:provider/provider.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();
  List<dynamic> _radarFrames = [];
  int _currentFrameIndex = 0;
  bool _isLoading = true;
  final int _colorScheme = 4; // Weather Channel scheme

  @override
  void initState() {
    super.initState();
    _fetchRadarData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _mapController.move(locationProvider.currentLatLng, 12);
    });
  }

  Future<void> _fetchRadarData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _radarFrames = [
            ...?data['radar']['past'],
            ...?data['radar']['nowcast'],
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching radar data: $e');
    }
  }

  Future<void> _changeLocation(String selectedCity, LocationProvider locationProvider) async {
    final cities = await _weatherService.searchCities(selectedCity.split(',')[0]);
    if (cities.isNotEmpty) {
      final location = cities.firstWhere(
        (c) => '${c['name']}${c['state'] != null ? ', ${c['state']}' : ''}, ${c['country']}' == selectedCity,
        orElse: () => cities.first,
      );
      
      final newLocation = LatLng(location['lat'], location['lon']);
      locationProvider.updateLocation(selectedCity, newLocation);
      
      _mapController.move(newLocation, 12);
    }
  }

  Future<void> _showLocationSearch(BuildContext context) async {
    final selectedCity = await showSearch<String>(
      context: context,
      delegate: CitySearchDelegate(_weatherService),
    );
    if (selectedCity != null) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await _changeLocation(selectedCity, locationProvider);
    }
  }

  void _changeFrame(int change) {
    setState(() {
      _currentFrameIndex = (_currentFrameIndex + change).clamp(0, _radarFrames.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locationProvider.currentCity),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showLocationSearch(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: locationProvider.currentLatLng,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
              if (_radarFrames.isNotEmpty)
                Opacity(
                  opacity: 0.7,
                  child: TileLayer(
                    urlTemplate:
                        'https://tilecache.rainviewer.com${_radarFrames[_currentFrameIndex]['path']}/512/{z}/{x}/{y}/$_colorScheme/1_1.png',
                    userAgentPackageName: 'com.example.weather_app',
                  ),
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: locationProvider.currentLatLng,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_radarFrames.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'prev',
                    onPressed: _currentFrameIndex > 0
                        ? () => _changeFrame(-1)
                        : null,
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'next',
                    onPressed: _currentFrameIndex < _radarFrames.length - 1
                        ? () => _changeFrame(1)
                        : null,
                    child: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}