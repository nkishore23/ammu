// lib/service/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // No longer strictly needed for logic here

class WeatherService {
  // IMPORTANT: Replace with your actual OpenWeatherMap API key
  final String apiKey =
      '0d7b64fc4a902365b77a69f85f8a1396'; // Ensure this is correct
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> fetchWeatherForecast(String cityName) async {
    double? lat;
    double? lon;

    // 1. Attempt to get location from address using geocoding package
    try {
      print('[WeatherService] Attempting geocoding for: "$cityName"');
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        lat = locations.first.latitude;
        lon = locations.first.longitude;
        print(
            '[WeatherService] Geocoding successful: Lat=$lat, Lon=$lon for "$cityName"');
      } else {
        // If geocoding returns an empty list, it means it couldn't find the location.
        print(
            '[WeatherService] Geocoding returned an empty list for: "$cityName". No fallback used.');
        throw Exception(
            'Location not found for "$cityName". Please check spelling.');
      }
    } catch (e) {
      // This catches any errors thrown by locationFromAddress (e.g., network, permissions, API issues).
      print('[WeatherService] Geocoding failed for "$cityName": $e');
      throw Exception(
          'Location lookup failed for "$cityName". Error: ${e.toString()}. Please check spelling or internet connection.');
    }

    // 3. If we have valid coordinates, fetch weather
    return await fetchWeatherForecastByCoordinates(lat, lon);
  }

  // This method directly fetches forecast using coordinates
  Future<Map<String, dynamic>> fetchWeatherForecastByCoordinates(
      double lat, double lon) async {
    try {
      final forecastUrl =
          '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      print(
          '[WeatherService] Fetching weather from OpenWeatherMap API: $forecastUrl');
      final response = await http.get(Uri.parse(forecastUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('[WeatherService] Weather data fetched successfully.');
        if (!responseData.containsKey('list') || responseData['list'] == null) {
          throw Exception('Invalid API response: "list" key missing or null.');
        }

        return responseData;
      } else {
        String errorMessage =
            'Failed to load weather forecast: HTTP ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody.containsKey('message')) {
            errorMessage += ' - ${errorBody['message']}';
          }
        } catch (e) {
          // Ignore JSON parsing error if body is not valid JSON
        }
        print('[WeatherService] API response error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception(
            'An unexpected error occurred during weather fetch: ${e.toString()}');
      }
    }
  }
}
