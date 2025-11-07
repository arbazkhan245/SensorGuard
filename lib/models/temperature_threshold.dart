class TemperatureThreshold {
  final String id;
  final String roomId;
  final double minTemp;
  final double maxTemp;
  final DateTime createdAt;
  final DateTime updatedAt;

  TemperatureThreshold({
    required this.id,
    required this.roomId,
    required this.minTemp,
    required this.maxTemp,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isBreached(double temperature) {
    return temperature < minTemp || temperature > maxTemp;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TemperatureThreshold.fromJson(Map<String, dynamic> json) {
    return TemperatureThreshold(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      minTemp: (json['minTemp'] as num).toDouble(),
      maxTemp: (json['maxTemp'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  TemperatureThreshold copyWith({
    String? id,
    String? roomId,
    double? minTemp,
    double? maxTemp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemperatureThreshold(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
