import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final LocalCacheService _cacheService;
  final NotificationService _notificationService;

  Map<String, List<Alert>> _alerts = {};
  bool _isLoading = false;
  String? _error;

  AlertProvider({
    required DatabaseService databaseService,
    required LocalCacheService cacheService,
    required NotificationService notificationService,
  })  : _databaseService = databaseService,
        _cacheService = cacheService,
        _notificationService = notificationService;

  // Getters
  Map<String, List<Alert>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Alert> getAlertsForRoom(String roomId) {
    return _alerts[roomId] ?? [];
  }

  List<Alert> getActiveAlerts(String roomId) {
    return getAlertsForRoom(roomId)
        .where((alert) => alert.status == AlertStatus.active)
        .toList();
  }

  int getUnacknowledgedAlertCount(String roomId) {
    return getAlertsForRoom(roomId)
        .where((alert) => alert.status == AlertStatus.active)
        .length;
  }

  // Initialize stream for real-time alerts
  void startListening(String roomId) {
    _databaseService.getActiveAlerts(roomId).listen(
      (alerts) {
        _alerts[roomId] = alerts;
        for (final alert in alerts) {
          if (alert.status == AlertStatus.active) {
            _notificationService.showAlertNotification(alert);
          }
        }
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to fetch alerts: $e';
        notifyListeners();
      },
    );
  }

  Future<void> createAlert(Alert alert) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.createAlert(alert);
      
      if (!_alerts.containsKey(alert.roomId)) {
        _alerts[alert.roomId] = [];
      }
      _alerts[alert.roomId]!.add(alert);
      
      await _cacheService.cacheAlert(alert);
      
      // Show notification immediately
      await _notificationService.showAlertNotification(alert);
      
      _error = null;
    } catch (e) {
      _error = 'Failed to create alert: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeAlert(String alertId, String roomId) async {
    try {
      final alert = _alerts[roomId]
          ?.firstWhere((a) => a.id == alertId, orElse: () => Alert(
            id: '',
            roomId: '',
            sensorId: '',
            type: AlertType.sensorError,
            temperature: 0,
            triggeredAt: DateTime.now(),
            status: AlertStatus.active,
            message: '',
            emailSent: false,
            smsSent: false,
          ));

      if (alert != null && alert.id.isNotEmpty) {
        final acknowledgedAlert =
            alert.copyWith(
              status: AlertStatus.acknowledged,
              acknowledgedAt: DateTime.now(),
            );
        
        await _databaseService.updateAlert(acknowledgedAlert);
        
        // Update local state
        final index = _alerts[roomId]!
            .indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _alerts[roomId]![index] = acknowledgedAlert;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }

  Future<void> resolveAlert(String alertId, String roomId) async {
    try {
      final alert = _alerts[roomId]
          ?.firstWhere((a) => a.id == alertId, orElse: () => Alert(
            id: '',
            roomId: '',
            sensorId: '',
            type: AlertType.sensorError,
            temperature: 0,
            triggeredAt: DateTime.now(),
            status: AlertStatus.active,
            message: '',
            emailSent: false,
            smsSent: false,
          ));

      if (alert != null && alert.id.isNotEmpty) {
        final resolvedAlert =
            alert.copyWith(
              status: AlertStatus.resolved,
              resolvedAt: DateTime.now(),
            );
        
        await _databaseService.updateAlert(resolvedAlert);
        
        // Update local state
        final index = _alerts[roomId]!
            .indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _alerts[roomId]![index] = resolvedAlert;
        }
        
        await _notificationService.cancelNotification(alertId);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to resolve alert: $e';
      notifyListeners();
    }
  }

  Future<void> loadCachedAlerts(String roomId) async {
    try {
      final cached = await _cacheService.getCachedAlerts(roomId);
      _alerts[roomId] = cached;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load cached alerts: $e';
    }
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }
}
