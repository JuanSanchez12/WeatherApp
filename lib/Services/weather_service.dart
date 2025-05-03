import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for handling all weather-related API calls
/// Communicates with OpenWeatherMap API to fetch weather data and city information
class WeatherService {
  // Base URLs for OpenWeatherMap API endpoints
  static const String _baseUrl = 'https://api.openweathermap.org/data/3.0/onecall';
  static const String _geoUrl = 'http://api.openweathermap.org/geo/1.0/direct';
  final String _apiKey = '7251d2a718e407ba1a6758861685671c'; // API key for authentication

  /// Searches for cities matching the given query
  /// Returns a list of city information maps (name, state, country, coordinates)
  /// [query] - The search string (city name)
  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    if (query.isEmpty) return []; // Return empty list for empty queries
    
    // Make API request to geocoding endpoint
    final response = await http.get(
      Uri.parse('$_geoUrl?q=$query&limit=5&appid=$_apiKey'),
    );

    // Process successful response
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Transform API response into standardized format
      return data.map((city) => {
        'name': city['name'],        // City name
        'state': city['state'],      // State/province (if available)
        'country': city['country'],  // Country code
        'lat': city['lat'],          // Latitude
        'lon': city['lon'],          // Longitude
      }).toList();
    }
    return []; // Return empty list on failure
  }

  /// Fetches complete weather data for given coordinates
  /// Returns a map containing current, hourly, and daily weather data
  /// [lat] - Latitude coordinate
  /// [lon] - Longitude coordinate
  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    // Make API request to OneCall endpoint with imperial units
    final response = await http.get(
      Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=imperial'),
    );

    // Process successful response
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    // Throw exception on failure
    throw Exception('Failed to load weather data');
  }
}