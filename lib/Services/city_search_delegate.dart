import 'package:flutter/material.dart';
import '../Services/weather_service.dart';

/// Custom search delegate for city search functionality
/// Handles city search UI and interactions with WeatherService
class CitySearchDelegate extends SearchDelegate<String> {
  final WeatherService weatherService; // Service for fetching city data
  List<Map<String, dynamic>> _cities = []; // Stores search results

  CitySearchDelegate(this.weatherService);

  @override
  List<Widget> buildActions(BuildContext context) {
    // Clear search query button (appears on the right)
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Back button (appears on the left)
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // Close search with empty result
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Show search results when a suggestion is selected
    return _buildCitySuggestions();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show search suggestions as user types
    return _buildCitySuggestions();
  }

  /// Builds the city suggestions list based on current query
  Widget _buildCitySuggestions() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // Fetch cities matching the current query
      future: weatherService.searchCities(query),
      builder: (context, snapshot) {
        // Show initial empty state when no query is entered
        if (query.isEmpty) return _buildEmptyState('Start typing a city name');
        
        // Show loading indicator while waiting for results
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        
        // Show empty state if no results found
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No cities found');
        }
        
        // Store and display the search results
        _cities = snapshot.data!;
        return ListView.builder(
          itemCount: _cities.length,
          itemBuilder: (context, index) {
            final city = _cities[index];
            // Format city name with state (if available) and country
            final cityName = '${city['name']}${city['state'] != null ? ', ${city['state']}' : ''}, ${city['country']}';
            
            return ListTile(
              title: Text(cityName),
              onTap: () {
                // Return selected city when tapped
                close(context, cityName);
              },
            );
          },
        );
      },
    );
  }

  /// Builds a loading indicator widget
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Builds an empty state message widget
  Widget _buildEmptyState(String message) {
    return Center(child: Text(message));
  }
}