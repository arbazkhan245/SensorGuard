import 'package:flutter/material.dart';
import '../models/temperature_reading.dart';

class RoomTile extends StatelessWidget {
  final TemperatureReading reading;

  const RoomTile({Key? key, required this.reading}) : super(key: key);

  Color _getTemperatureColor(double temperature) {
    if (temperature < 15) return Colors.blue;
    if (temperature < 20) return Colors.green;
    if (temperature < 25) return Colors.orange;
    return Colors.red;
  }

  Icon _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'error':
        return const Icon(Icons.error, color: Colors.red, size: 16);
      case 'offline':
        return const Icon(Icons.signal_cellular_off, color: Colors.grey, size: 16);
      default:
        return const Icon(Icons.help, color: Colors.grey, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempColor = _getTemperatureColor(reading.temperature);

    return Container(
      decoration: BoxDecoration(
        color: tempColor.withOpacity(0.2),
        border: Border.all(color: tempColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.thermostat,
                color: tempColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${reading.temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: tempColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatusIcon(reading.status),
              const SizedBox(width: 4),
              Text(
                reading.roomId,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
