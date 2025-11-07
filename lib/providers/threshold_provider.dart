import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';

class ThresholdProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final LocalCacheService _cacheService;

  Map<String, TemperatureThreshold> _thresholds = {};
  bool _isLoading = false;
  String? _error;

  static const double minValidTemp = -50.0;
  static const double maxValidTemp = 100.0;

  ThresholdProvider({
    required DatabaseService databaseService,
    required LocalCacheService cacheService,
  })  : _databaseService = databaseService,
        _cacheService = cacheService;

  // Getters
  Map<String, TemperatureThreshold> get thresholds => _thresholds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TemperatureThreshold? getThresholdForRoom(String roomId) {
    return _thresholds[roomId];
  }

  bool isValidThreshold(double minTemp, double maxTemp) {
    return minTemp >= minValidTemp &&
        maxTemp <= maxValidTemp &&
        minTemp < maxTemp;
  }

  String? validateThreshold(double temp) {
    if (temp < minValidTemp || temp > maxValidTemp) {
      return 'Temperature must be between $minValidTemp°C and $maxValidTemp°C';
    }
    return null;
  }

  // Initialize stream for real-time updates
  void startListening(String roomId) {
    _databaseService.getThreshold(roomId).listen(
      (threshold) {
        if (threshold != null) {
          _thresholds[roomId] = threshold;
          _cacheService.cacheThreshold(threshold);
          _error = null;
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Failed to fetch threshold: $e';
        notifyListeners();
      },
    );
  }

  Future<void> setThreshold(
    String roomId,
    double minTemp,
    double maxTemp,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final validationError = validateThreshold(minTemp) ??
          validateThreshold(maxTemp);
      if (validationError != null) {
        _error = validationError;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (minTemp >= maxTemp) {
        _error =
            'Minimum temperature must be less than maximum temperature';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final now = DateTime.now();
      final threshold = TemperatureThreshold(
        id: '${roomId}_${now.millisecondsSinceEpoch}',
        roomId: roomId,
        minTemp: minTemp,
        maxTemp: maxTemp,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.setThreshold(threshold);
      _thresholds[roomId] = threshold;
      _error = null;
    } catch (e) {
      _error = 'Failed to set threshold: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedThreshold(String roomId) async {
    try {
      final cached = await _cacheService.getCachedThreshold(roomId);
      if (cached != null) {
        _thresholds[roomId] = cached;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load cached threshold: $e';
    }
  }

  void clearThresholds() {
    _thresholds.clear();
    notifyListeners();
  }
}
