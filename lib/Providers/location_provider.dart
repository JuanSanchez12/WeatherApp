import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider with ChangeNotifier {
  String _currentCity = 'Atlanta, US'; // Default
  LatLng _currentLatLng = const LatLng(33.7490, -84.3880);

  String get currentCity => _currentCity;
  LatLng get currentLatLng => _currentLatLng;

  void updateLocation(String city, LatLng latLng) {
    _currentCity = city;
    _currentLatLng = latLng;
    notifyListeners(); 
  }
}