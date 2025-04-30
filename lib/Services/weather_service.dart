import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/3.0/onecall';
  final String _apiKey = '7251d2a718e407ba1a6758861685671c';

  // Atlanta coordinates
  static const double atlantaLat = 33.7490;
  static const double atlantaLon = -84.3880;

  Future<double> getAtlantaTemperature() async {
    final response = await http.get(
      Uri.parse('$_baseUrl?lat=$atlantaLat&lon=$atlantaLon&appid=$_apiKey&units=imperial'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['current']['temp'];
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
}