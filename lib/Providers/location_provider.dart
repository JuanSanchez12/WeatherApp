import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Manages the app's current location state (city name and coordinates)
/// Notifies listeners when location changes
class LocationProvider with ChangeNotifier {
  // Default location (Atlanta, US)
  String _currentCity = 'Atlanta, US';
  LatLng _currentLatLng = const LatLng(33.7490, -84.3880);

  /// Getter for current city name
  String get currentCity => _currentCity;
  
  /// Getter for current coordinates (latitude/longitude)
  LatLng get currentLatLng => _currentLatLng;

  /// Updates the current location and notifies all listeners
  /// [city] - New city name string (e.g. "New York, US")
  /// [latLng] - New coordinates as LatLng object
  void updateLocation(String city, LatLng latLng) {
    _currentCity = city;
    _currentLatLng = latLng;
    notifyListeners(); // Notify all listening widgets to rebuild
  }
}