import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // You'll need to get a free API key from https://openweathermap.org/api
  // For now, using a placeholder. Replace with your actual API key.
  static const String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>?> getWeather(double latitude, double longitude) async {
    // Return mock data if API key is not set
    if (apiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      print('Weather API key not set. Using mock data.');
      return {
        'temperature': 29.9,
        'humidity': 56,
        'windspeed': 3.6,
        'weather': 'Clear sky',
        'description': 'clear sky',
      };
    }

    try {
      final url = Uri.parse(
        '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': (data['main']['temp'] as num).toDouble(),
          'humidity': data['main']['humidity'],
          'windspeed': (data['wind']['speed'] as num).toDouble() * 3.6, // Convert m/s to km/h
          'weather': data['weather'][0]['main'],
          'description': data['weather'][0]['description'],
        };
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        // Return mock data on API error
        return {
          'temperature': 29.9,
          'humidity': 56,
          'windspeed': 3.6,
          'weather': 'Clear sky',
          'description': 'clear sky',
        };
      }
    } catch (e) {
      print('Error fetching weather: $e');
      // Return mock data for development/testing
      return {
        'temperature': 29.9,
        'humidity': 56,
        'windspeed': 3.6,
        'weather': 'Clear sky',
        'description': 'clear sky',
      };
    }
  }
}

