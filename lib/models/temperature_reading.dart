import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class TemperatureReading {
  final String id;
  final String? sensorId;
  final String? roomId;
  final double temperature;
  final String? humidity;
  final DateTime timestamp;
  final String? status; // 'active', 'error', 'offline'
  final bool? alertTriggered;
  final String? source;

  TemperatureReading({
    required this.id,
    this.sensorId,
    this.roomId,
    required this.temperature,
    this.humidity,
    required this.timestamp,
    this.status = 'active',
    this.alertTriggered,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorId': sensorId,
      'roomId': roomId,
      'temperature': temperature.toString(),
      'humidity': humidity ?? '--',
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'alert_triggered': alertTriggered ?? false,
      'source': source ?? 'app',
    };
  }

  factory TemperatureReading.fromJson(Map<String, dynamic> json, String docId) {
    // Handle temperature as string or number
    double temp;
    if (json['temperature'] is String) {
      final tempStr = json['temperature'] as String;
      temp = double.tryParse(tempStr) ?? 0.0;
    } else {
      temp = (json['temperature'] as num?)?.toDouble() ?? 0.0;
    }

    // Handle humidity as string
    final humidityStr = json['humidity']?.toString() ?? '--';

    // Handle timestamp as string
    DateTime timestamp;
    if (json['timestamp'] is String) {
      try {
        timestamp = DateTime.parse(json['timestamp'] as String);
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    return TemperatureReading(
      id: docId,
      sensorId: json['sensorId']?.toString(),
      roomId: json['roomId']?.toString(),
      temperature: temp,
      humidity: humidityStr == '--' ? null : humidityStr,
      timestamp: timestamp,
      status: json['status']?.toString(),
      alertTriggered: json['alert_triggered'] as bool? ?? false,
      source: json['source']?.toString(),
    );
  }
}
