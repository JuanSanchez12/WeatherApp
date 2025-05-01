import 'package:flutter/material.dart';
import '../Services/weather_service.dart';

class CitySearchDelegate extends SearchDelegate<String> {
  final WeatherService weatherService;
  List<Map<String, dynamic>> _cities = [];

  CitySearchDelegate(this.weatherService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildCitySuggestions();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildCitySuggestions();
  }

  Widget _buildCitySuggestions() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: weatherService.searchCities(query),
      builder: (context, snapshot) {
        if (query.isEmpty) return _buildEmptyState('Start typing a city name');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No cities found');
        }
        
        _cities = snapshot.data!;
        return ListView.builder(
          itemCount: _cities.length,
          itemBuilder: (context, index) {
            final city = _cities[index];
            final cityName = '${city['name']}${city['state'] != null ? ', ${city['state']}' : ''}, ${city['country']}';
            
            return ListTile(
              title: Text(cityName),
              onTap: () {
                close(context, cityName);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message));
  }
}