import 'package:flutter/material.dart';
import '../providers/temperature_provider.dart';
import '../models/temperature_reading.dart';

enum TemperatureStatus { cold, cool, optimal, warm }

class RoomDisplayData {
  RoomDisplayData({
    required this.id,
    required this.name,
    required this.temperature,
    required this.area,
    required this.status,
    required this.icon,
    this.humidity,
    this.isEnergyEfficient = false,
  });

  final String id;
  final String name;
  final double temperature;
  final double area;
  final TemperatureStatus status;
  final IconData icon;
  final String? humidity;
  final bool isEnergyEfficient;

  String get statusLabel => _statusLabels[status]!;
  Color get statusColor => _statusColors[status]!;
  List<Color> get gradientColors => _statusGradients[status]!;
}

Color temperatureStatusColor(TemperatureStatus status) => _statusColors[status]!;
String temperatureStatusLabel(TemperatureStatus status) => _statusLabels[status]!;
List<Color> temperatureStatusGradient(TemperatureStatus status) =>
    _statusGradients[status]!;

const Map<TemperatureStatus, String> _statusLabels = {
  TemperatureStatus.cold: 'Cold',
  TemperatureStatus.cool: 'Cool',
  TemperatureStatus.optimal: 'Optimal',
  TemperatureStatus.warm: 'Warm',
};

const Map<TemperatureStatus, Color> _statusColors = {
  TemperatureStatus.cold: Color(0xFF3B82F6),
  TemperatureStatus.cool: Color(0xFF22C55E),
  TemperatureStatus.optimal: Color(0xFFF59E0B),
  TemperatureStatus.warm: Color(0xFFEF4444),
};

const Map<TemperatureStatus, List<Color>> _statusGradients = {
  TemperatureStatus.cold: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
  TemperatureStatus.cool: [Color(0xFF0F172A), Color(0xFF047857)],
  TemperatureStatus.optimal: [Color(0xFF0F172A), Color(0xFFD97706)],
  TemperatureStatus.warm: [Color(0xFF0F172A), Color(0xFFB91C1C)],
};

const Map<String, String> _roomNameOverrides = {
  'livingroom': 'Living Room',
  'kitchen': 'Kitchen',
  'garage': 'Garage',
  'bedroom': 'Bedroom',
  'bedroom2': 'Bedroom 2',
  'diningroom': 'Dining Room',
  'bathroom': 'Bathroom',
  'office': 'Office',
};

const Map<String, double> _roomAreaMap = {
  'livingroom': 2.4,
  'kitchen': 1.4,
  'garage': 1.9,
  'bedroom': 1.8,
  'bedroom2': 2.0,
  'diningroom': 2.3,
  'bathroom': 1.2,
  'office': 1.6,
};

const Map<String, IconData> _roomIconMap = {
  'livingroom': Icons.weekend,
  'kitchen': Icons.kitchen,
  'garage': Icons.directions_car,
  'bedroom': Icons.bed,
  'bedroom2': Icons.king_bed,
  'diningroom': Icons.restaurant,
  'bathroom': Icons.bathtub,
  'office': Icons.chair_alt,
};

const List<Map<String, dynamic>> _fallbackRooms = [
  {
    'id': 'livingroom',
    'name': 'Living Room',
    'temperature': 22.5,
    'area': 2.4,
    'humidity': '53%',
  },
  {
    'id': 'kitchen',
    'name': 'Kitchen',
    'temperature': 24.8,
    'area': 1.4,
    'humidity': '48%',
  },
  {
    'id': 'garage',
    'name': 'Garage',
    'temperature': 18.3,
    'area': 1.9,
    'humidity': '60%',
  },
  {
    'id': 'bedroom',
    'name': 'Bedroom',
    'temperature': 20.2,
    'area': 1.8,
    'humidity': '55%',
  },
  {
    'id': 'bedroom2',
    'name': 'Bedroom 2',
    'temperature': 21.8,
    'area': 2.0,
    'humidity': '57%',
  },
  {
    'id': 'diningroom',
    'name': 'Dining Room',
    'temperature': 23.1,
    'area': 2.3,
    'humidity': '50%',
  },
];

List<RoomDisplayData> buildRoomDisplayData(TemperatureProvider provider) {
  final readings = provider.latestReadings.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final fallbackRooms = _fallbackRooms
      .map(
        (room) => _createRoomData(
          id: room['id'] as String,
          name: room['name'] as String,
          temperature: (room['temperature'] as num).toDouble(),
          area: (room['area'] as num).toDouble(),
          humidity: room['humidity'] as String?,
        ),
      )
      .toList();

  if (readings.isEmpty) {
    return fallbackRooms;
  }

  final List<TemperatureReading> remainingReadings = List.from(readings);
  final List<RoomDisplayData> rooms = [];

  for (var index = 0; index < _fallbackRooms.length; index++) {
    final fallback = _fallbackRooms[index];
    final normalizedId = _normalizeKey(fallback['id'] as String);
    final reading = _takeMatchingReading(remainingReadings, normalizedId);

    final temperature =
        reading?.temperature ?? (fallback['temperature'] as num).toDouble();
    final humidity = reading?.humidity ?? fallback['humidity'] as String?;

    rooms.add(
      _createRoomData(
        id: fallback['id'] as String,
        name: fallback['name'] as String,
        temperature: temperature,
        area: (fallback['area'] as num).toDouble(),
        humidity: humidity,
      ),
    );
  }

  // Any extra readings (unknown rooms) are appended with generated names.
  if (remainingReadings.isNotEmpty) {
    for (final reading in remainingReadings) {
      final generatedName = _formatRoomName(
        reading.roomId ?? reading.sensorId ?? 'Room ${rooms.length + 1}',
        rooms.length,
      );
      rooms.add(
        _createRoomData(
          id: reading.roomId ?? reading.sensorId ?? generatedName,
          name: generatedName,
          temperature: reading.temperature,
          area: 1.6 + rooms.length * 0.2,
          humidity: reading.humidity,
        ),
      );
    }
  }

  return rooms;
}

TemperatureReading? _takeMatchingReading(
  List<TemperatureReading> readings,
  String normalizedFallbackId,
) {
  final index = readings.indexWhere((reading) {
    final roomKey = _normalizeKey(reading.roomId ?? '');
    final sensorKey = _normalizeKey(reading.sensorId ?? '');
    if (roomKey == normalizedFallbackId || sensorKey == normalizedFallbackId) {
      return true;
    }
    return false;
  });

  if (index != -1) {
    return readings.removeAt(index);
  }

  if (readings.isEmpty) {
    return null;
  }

  // No direct match, take the most recent reading.
  return readings.removeAt(0);
}

TemperatureStatus _statusFromTemperature(double temperature) {
  if (temperature < 18) return TemperatureStatus.cold;
  if (temperature < 22) return TemperatureStatus.cool;
  if (temperature <= 25) return TemperatureStatus.optimal;
  return TemperatureStatus.warm;
}

RoomDisplayData _createRoomData({
  required String id,
  required String name,
  required double temperature,
  required double area,
  String? humidity,
}) {
  final normalized = _normalizeKey(id);
  return RoomDisplayData(
    id: id,
    name: name,
    temperature: temperature,
    area: area,
    status: _statusFromTemperature(temperature),
    icon: _roomIconMap[normalized] ?? Icons.home_outlined,
    humidity: humidity,
    isEnergyEfficient: temperature >= 20 && temperature <= 24,
  );
}

String _formatRoomName(String input, int index) {
  final trimmed = input.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (trimmed.isEmpty) {
    return 'Room ${index + 1}';
  }
  return trimmed
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _normalizeKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
