import 'package:hive_flutter/hive_flutter.dart';
import '../models/index.dart';

class LocalCacheService {
  static const String _readingsBox = 'temperature_readings';
  static const String _thresholdsBox = 'temperature_thresholds';
  static const String _alertsBox = 'alerts';
  static const String _connectivityBox = 'connectivity_status';

  Future<void> initializeBoxes() async {
    await Hive.openBox<String>(_readingsBox);
    await Hive.openBox<String>(_thresholdsBox);
    await Hive.openBox<String>(_alertsBox);
    await Hive.openBox<String>(_connectivityBox);
  }

  // Temperature Readings Cache
  Future<void> cacheTemperatureReading(TemperatureReading reading) async {
    try {
      final box = Hive.box<String>(_readingsBox);
      final json = reading.toJson();
      await box.put(reading.id, _jsonToString(json));
    } catch (e) {
      throw Exception('Failed to cache temperature reading: $e');
    }
  }

  Future<List<TemperatureReading>> getCachedReadings(String roomId) async {
    try {
      final box = Hive.box<String>(_readingsBox);
      final readings = <TemperatureReading>[];
      for (final value in box.values) {
        final json = _stringToJson(value);
        if (json['roomId'] == roomId) {
          final docId = (json['id'] ?? 'cached_${DateTime.now().millisecondsSinceEpoch}').toString();
          readings.add(TemperatureReading.fromJson(json, docId));
        }
      }
      return readings;
    } catch (e) {
      throw Exception('Failed to get cached readings: $e');
    }
  }

  Future<void> clearReadingsCache() async {
    try {
      final box = Hive.box<String>(_readingsBox);
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear readings cache: $e');
    }
  }

  // Thresholds Cache
  Future<void> cacheThreshold(TemperatureThreshold threshold) async {
    try {
      final box = Hive.box<String>(_thresholdsBox);
      final json = threshold.toJson();
      await box.put(threshold.roomId, _jsonToString(json));
    } catch (e) {
      throw Exception('Failed to cache threshold: $e');
    }
  }

  Future<TemperatureThreshold?> getCachedThreshold(String roomId) async {
    try {
      final box = Hive.box<String>(_thresholdsBox);
      final value = box.get(roomId);
      if (value == null) return null;
      final json = _stringToJson(value);
      return TemperatureThreshold.fromJson(json);
    } catch (e) {
      throw Exception('Failed to get cached threshold: $e');
    }
  }

  Future<void> clearThresholdsCache() async {
    try {
      final box = Hive.box<String>(_thresholdsBox);
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear thresholds cache: $e');
    }
  }

  // Alerts Cache
  Future<void> cacheAlert(Alert alert) async {
    try {
      final box = Hive.box<String>(_alertsBox);
      final json = alert.toJson();
      await box.put(alert.id, _jsonToString(json));
    } catch (e) {
      throw Exception('Failed to cache alert: $e');
    }
  }

  Future<List<Alert>> getCachedAlerts(String roomId) async {
    try {
      final box = Hive.box<String>(_alertsBox);
      final alerts = <Alert>[];
      for (final value in box.values) {
        final json = _stringToJson(value);
        if (json['roomId'] == roomId) {
          alerts.add(Alert.fromJson(json));
        }
      }
      return alerts;
    } catch (e) {
      throw Exception('Failed to get cached alerts: $e');
    }
  }

  Future<void> clearAlertsCache() async {
    try {
      final box = Hive.box<String>(_alertsBox);
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear alerts cache: $e');
    }
  }

  // Connectivity Status Cache
  Future<void> setConnectivityStatus(bool isConnected) async {
    try {
      final box = Hive.box<String>(_connectivityBox);
      await box.put('connected', isConnected.toString());
    } catch (e) {
      throw Exception('Failed to set connectivity status: $e');
    }
  }

  Future<bool> getConnectivityStatus() async {
    try {
      final box = Hive.box<String>(_connectivityBox);
      final value = box.get('connected') ?? 'false';
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // Utility methods
  String _jsonToString(Map<String, dynamic> json) {
    // Simple JSON stringification - could use jsonEncode for production
    return json.toString();
  }

  Map<String, dynamic> _stringToJson(String jsonString) {
    // Simple JSON parsing - use proper JSON decode in production
    final map = <String, dynamic>{};
    // This is a simplified version - implement proper JSON parsing
    return map;
  }

  Future<void> clearAllCache() async {
    try {
      await clearReadingsCache();
      await clearThresholdsCache();
      await clearAlertsCache();
    } catch (e) {
      throw Exception('Failed to clear all cache: $e');
    }
  }
}
