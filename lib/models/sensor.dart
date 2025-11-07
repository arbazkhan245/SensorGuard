class Sensor {
  final String id;
  final String roomId;
  final String name;
  final String location;
  final bool isActive;
  final DateTime lastUpdate;

  Sensor({
    required this.id,
    required this.roomId,
    required this.name,
    required this.location,
    required this.isActive,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'name': name,
      'location': location,
      'isActive': isActive,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      isActive: json['isActive'] as bool? ?? true,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  Sensor copyWith({
    String? id,
    String? roomId,
    String? name,
    String? location,
    bool? isActive,
    DateTime? lastUpdate,
  }) {
    return Sensor(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
