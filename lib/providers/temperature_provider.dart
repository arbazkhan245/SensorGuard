import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';

class TemperatureProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final LocalCacheService _cacheService;

  Map<String, TemperatureReading> _latestReadings = {};
  bool _isLoading = false;
  String? _error;

  TemperatureProvider({
    required DatabaseService databaseService,
    required LocalCacheService cacheService,
  })  : _databaseService = databaseService,
        _cacheService = cacheService;

  // Getters
  Map<String, TemperatureReading> get latestReadings => _latestReadings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TemperatureReading? getReadingForRoom(String roomId) {
    return _latestReadings.values
        .firstWhere(
          (reading) => reading.roomId == roomId,
          orElse: () => TemperatureReading(
            id: 'empty',
            sensorId: '',
            roomId: roomId,
            temperature: 0.0,
            timestamp: DateTime.now(),
          ),
        );
  }

  TemperatureThreshold? _currentThreshold;

  // Set threshold for alert checking
  void setThreshold(TemperatureThreshold? threshold) {
    _currentThreshold = threshold;
  }

  // Initialize stream for real-time updates from Realtime Database
  void startListening() {
    _databaseService.getRealtimeTemperature().listen(
      (temperature) {
        if (temperature != null) {
          // Check if threshold is breached
          bool alertTriggered = false;
          if (_currentThreshold != null && _currentThreshold!.isBreached(temperature)) {
            alertTriggered = true;
          }

          // Create a reading from real-time data
          final reading = TemperatureReading(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            temperature: temperature,
            timestamp: DateTime.now(),
            source: 'realtime',
            alertTriggered: alertTriggered,
          );

          // Save to Firestore
          _databaseService.saveTemperatureReading(reading).catchError((e) {
            print('Error saving to Firestore: $e');
          });

          // Store in memory
          _latestReadings['realtime'] = reading;
          _cacheService.cacheTemperatureReading(reading);
          _error = null;
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Failed to fetch real-time temperature: $e';
        notifyListeners();
      },
    );
  }

  // Get latest readings from Firestore
  void startListeningToFirestore({int limit = 100}) {
    _databaseService.getLatestReadings(limit: limit).listen(
      (readings) {
        if (readings.isNotEmpty) {
          // Update latest readings from Firestore
          for (final reading in readings) {
            final key = reading.sensorId ?? reading.id;
            _latestReadings[key] = reading;
            _cacheService.cacheTemperatureReading(reading);
          }
          _error = null;
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Failed to fetch readings from Firestore: $e';
        notifyListeners();
      },
    );
  }

  Future<void> addTemperatureReading(TemperatureReading reading) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.saveTemperatureReading(reading);
      final key = reading.sensorId ?? reading.id;
      _latestReadings[key] = reading;
      _error = null;
    } catch (e) {
      _error = 'Failed to add temperature reading: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedReadings(String roomId) async {
    try {
      final cached = await _cacheService.getCachedReadings(roomId);
      for (final reading in cached) {
        final key = reading.sensorId ?? reading.id;
        _latestReadings[key] = reading;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load cached readings: $e';
    }
  }

  void clearReadings() {
    _latestReadings.clear();
    notifyListeners();
  }

  // Get today's readings
  List<TemperatureReading> getTodaysReadings() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _latestReadings.values
        .where((reading) =>
            reading.timestamp.isAfter(startOfDay) &&
            reading.timestamp.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get critical readings (above threshold or very high/low)
  List<TemperatureReading> getCriticalReadings(
      Map<String, TemperatureThreshold> thresholds) {
    final todaysReadings = getTodaysReadings();
    return todaysReadings.where((reading) {
      final threshold = thresholds[reading.roomId];
      if (threshold != null && threshold.isBreached(reading.temperature)) {
        return true;
      }
      // Also consider very high temperatures as critical (> 60°C)
      return reading.temperature > 60.0;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get latest room temperature (average of latest readings or single sensor)
  double? getLatestRoomTemperature() {
    if (_latestReadings.isEmpty) return null;
    // Get the most recent reading
    final sortedReadings = _latestReadings.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedReadings.first.temperature;
  }
}
