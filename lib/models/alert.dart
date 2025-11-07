enum AlertType { temperatureTooHigh, temperatureTooLow, sensorError }

enum AlertStatus { active, acknowledged, resolved }

class Alert {
  final String id;
  final String roomId;
  final String sensorId;
  final AlertType type;
  final double temperature;
  final double? threshold;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final AlertStatus status;
  final String message;
  final bool emailSent;
  final bool smsSent;

  Alert({
    required this.id,
    required this.roomId,
    required this.sensorId,
    required this.type,
    required this.temperature,
    this.threshold,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.status,
    required this.message,
    required this.emailSent,
    required this.smsSent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'sensorId': sensorId,
      'type': type.toString(),
      'temperature': temperature,
      'threshold': threshold,
      'triggeredAt': triggeredAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'status': status.toString(),
      'message': message,
      'emailSent': emailSent,
      'smsSent': smsSent,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      sensorId: json['sensorId'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AlertType.sensorError,
      ),
      temperature: (json['temperature'] as num).toDouble(),
      threshold: json['threshold'] != null
          ? (json['threshold'] as num).toDouble()
          : null,
      triggeredAt: DateTime.parse(json['triggeredAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      status: AlertStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => AlertStatus.active,
      ),
      message: json['message'] as String,
      emailSent: json['emailSent'] as bool? ?? false,
      smsSent: json['smsSent'] as bool? ?? false,
    );
  }

  Alert copyWith({
    String? id,
    String? roomId,
    String? sensorId,
    AlertType? type,
    double? temperature,
    double? threshold,
    DateTime? triggeredAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    AlertStatus? status,
    String? message,
    bool? emailSent,
    bool? smsSent,
  }) {
    return Alert(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      sensorId: sensorId ?? this.sensorId,
      type: type ?? this.type,
      temperature: temperature ?? this.temperature,
      threshold: threshold ?? this.threshold,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      message: message ?? this.message,
      emailSent: emailSent ?? this.emailSent,
      smsSent: smsSent ?? this.smsSent,
    );
  }
}
