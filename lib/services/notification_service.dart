import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/index.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late final AudioPlayer _audioPlayer;

  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _audioPlayer = AudioPlayer();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> showAlertNotification(Alert alert) async {
    try {
      final title = _getAlertTitle(alert.type);
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'temperature_alerts',
        'Temperature Alerts',
        channelDescription: 'Notifications for temperature threshold breaches',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        alert.id.hashCode,
        title,
        alert.message,
        platformChannelSpecifics,
      );

      // Play alert sound
      await playAlertSound();
    } catch (e) {
      throw Exception('Failed to show notification: $e');
    }
  }

  Future<void> showSimpleNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'general_notifications',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      throw Exception('Failed to show notification: $e');
    }
  }

  Future<void> playAlertSound() async {
    try {
      // Play a system alert sound or custom alert
      // This can be replaced with a custom audio file path
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      // Silent failure for audio playback
      print('Failed to play alert sound: $e');
    }
  }

  Future<void> cancelNotification(String alertId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(alertId.hashCode);
    } catch (e) {
      throw Exception('Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      throw Exception('Failed to cancel all notifications: $e');
    }
  }

  String _getAlertTitle(AlertType type) {
    switch (type) {
      case AlertType.temperatureTooHigh:
        return 'High Temperature Alert';
      case AlertType.temperatureTooLow:
        return 'Low Temperature Alert';
      case AlertType.sensorError:
        return 'Sensor Error';
    }
  }

  // Email and SMS support (placeholder for integration)
  Future<void> sendEmailAlert(Alert alert, String email) async {
    try {
      // Integrate with email service (e.g., SendGrid, Firebase Functions)
      // await _emailService.sendAlert(alert, email);
      print('Email alert sent to $email for alert: ${alert.id}');
    } catch (e) {
      throw Exception('Failed to send email alert: $e');
    }
  }

  Future<void> sendSmsAlert(Alert alert, String phoneNumber) async {
    try {
      // Integrate with SMS service (e.g., Twilio)
      // await _smsService.sendAlert(alert, phoneNumber);
      print('SMS alert sent to $phoneNumber for alert: ${alert.id}');
    } catch (e) {
      throw Exception('Failed to send SMS alert: $e');
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
