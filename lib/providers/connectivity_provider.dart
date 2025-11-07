import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final LocalCacheService _cacheService;

  bool _isConnected = true;
  int _reconnectionAttempts = 0;
  static const int maxReconnectionAttempts = 10;
  static const Duration reconnectionInterval = Duration(seconds: 30);

  ConnectivityProvider({
    required DatabaseService databaseService,
    required LocalCacheService cacheService,
  })  : _databaseService = databaseService,
        _cacheService = cacheService;

  // Getters
  bool get isConnected => _isConnected;
  int get reconnectionAttempts => _reconnectionAttempts;

  // Initialize connection monitoring
  void startMonitoring() {
    _databaseService.getConnectionStatus().listen((isConnected) {
      if (isConnected) {
        _isConnected = true;
        _reconnectionAttempts = 0;
        _cacheService.setConnectivityStatus(true);
      } else {
        _isConnected = false;
        _cacheService.setConnectivityStatus(false);
        _startReconnectionAttempts();
      }
      notifyListeners();
    });
  }

  void _startReconnectionAttempts() async {
    while (!_isConnected && _reconnectionAttempts < maxReconnectionAttempts) {
      await Future.delayed(reconnectionInterval);
      _reconnectionAttempts++;
      
      try {
        await _databaseService.goOnline();
        // Check if connection restored
        if (_databaseService.getConnectionStatus().isEmpty == false) {
          _isConnected = true;
          _reconnectionAttempts = 0;
        }
      } catch (e) {
        print('Reconnection attempt $_reconnectionAttempts failed: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> goOffline() async {
    try {
      await _databaseService.goOffline();
      _isConnected = false;
      await _cacheService.setConnectivityStatus(false);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to go offline: $e');
    }
  }

  Future<void> goOnline() async {
    try {
      await _databaseService.goOnline();
      _isConnected = true;
      _reconnectionAttempts = 0;
      await _cacheService.setConnectivityStatus(true);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to go online: $e');
    }
  }
}
