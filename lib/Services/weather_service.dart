import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/3.0/onecall';
  static const String _geoUrl = 'http://api.openweathermap.org/geo/1.0/direct';
  final String _apiKey = '7251d2a718e407ba1a6758861685671c';

  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    if (query.isEmpty) return [];
    
    final response = await http.get(
      Uri.parse('$_geoUrl?q=$query&limit=5&appid=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((city) => {
        'name': city['name'],
        'state': city['state'],
        'country': city['country'],
        'lat': city['lat'],
        'lon': city['lon'],
      }).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=imperial'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load weather data');
  }
}