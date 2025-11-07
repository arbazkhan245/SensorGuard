import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final WeatherService _weatherService;

  Map<String, String>? _locationDetails;
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _error;
  bool _autoRefresh = true;
  int _autoRefreshInterval = 30; // seconds

  LocationProvider({
    required LocationService locationService,
    required WeatherService weatherService,
  })  : _locationService = locationService,
        _weatherService = weatherService;

  // Getters
  Map<String, String>? get locationDetails => _locationDetails;
  Map<String, dynamic>? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get autoRefresh => _autoRefresh;
  int get autoRefreshInterval => _autoRefreshInterval;

  Future<void> fetchLocationAndWeather() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _error = 'Failed to get location';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get location details (city, etc.)
      _locationDetails = await _locationService.getLocationDetails(position);

      // Get weather data
      _weatherData = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      _error = null;
    } catch (e) {
      _error = 'Error fetching location/weather: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAutoRefresh(bool enabled) {
    _autoRefresh = enabled;
    notifyListeners();
  }

  void setAutoRefreshInterval(int seconds) {
    _autoRefreshInterval = seconds;
    notifyListeners();
  }

  void startAutoRefresh() {
    if (_autoRefresh && !_isLoading) {
      Future.delayed(Duration(seconds: _autoRefreshInterval), () {
        if (_autoRefresh && !_isLoading) {
          fetchLocationAndWeather().then((_) {
            startAutoRefresh();
          });
        }
      });
    }
  }

  void stopAutoRefresh() {
    _autoRefresh = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

