import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temperature_provider.dart';
import '../utils/room_display_utils.dart';
import 'all_rooms_screen.dart';

class SmartHomeMapScreen extends StatelessWidget {
  const SmartHomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: SafeArea(
        child: Consumer<TemperatureProvider>(
          builder: (context, tempProvider, _) {
            final rooms = buildRoomDisplayData(tempProvider);
            final selectedRoom = rooms.isNotEmpty ? rooms.first : null;

            return Column(
              children: [
                const _Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const _TemperatureIndicators(),
                        const SizedBox(height: 16),
                        _MapOverview(rooms: rooms),
                        const SizedBox(height: 16),
                        if (selectedRoom != null)
                          _RoomOverviewCard(room: selectedRoom),
                        const SizedBox(height: 16),
                        _ActionButtons(onAllRoomsTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllRoomsScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.home, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Smart Home Map',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refreshing view...')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureIndicators extends StatelessWidget {
  const _TemperatureIndicators();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IndicatorChip(
            label: 'Cold',
            description: '<18°C',
            color: temperatureStatusColor(TemperatureStatus.cold),
          ),
          _IndicatorChip(
            label: 'Cool',
            description: '18-22°C',
            color: temperatureStatusColor(TemperatureStatus.cool),
          ),
          _IndicatorChip(
            label: 'Optimal',
            description: '22-25°C',
            color: temperatureStatusColor(TemperatureStatus.optimal),
          ),
          _IndicatorChip(
            label: 'Warm',
            description: '>25°C',
            color: temperatureStatusColor(TemperatureStatus.warm),
          ),
        ],
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  const _IndicatorChip({
    required this.label,
    required this.description,
    required this.color,
  });

  final String label;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MapOverview extends StatelessWidget {
  const _MapOverview({required this.rooms});

  final List<RoomDisplayData> rooms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = rooms.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'House Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final tileWidth = (width - 24) / 2; // spacing 12*2
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(tiles.length, (index) {
                  final room = tiles[index];
                  final isTall = index == 1 || index == 4;
                  return _MapRoomTile(
                    room: room,
                    width: tileWidth,
                    height: isTall ? 190 : 140,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapRoomTile extends StatelessWidget {
  const _MapRoomTile({
    required this.room,
    required this.width,
    required this.height,
  });

  final RoomDisplayData room;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: room.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: room.statusColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(room.icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${room.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            room.statusLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomOverviewCard extends StatelessWidget {
  const _RoomOverviewCard({required this.room});

  final RoomDisplayData room;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: room.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: room.statusColor.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(room.icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                room.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(
                label: 'Area',
                value: '${room.area.toStringAsFixed(1)} m²',
              ),
              _InfoChip(
                label: 'Status',
                value: room.statusLabel,
              ),
              _InfoChip(
                label: 'Humidity',
                value: room.humidity ?? '--',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                room.isEnergyEfficient ? Icons.bolt : Icons.warning_amber_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                room.isEnergyEfficient ? 'Energy Efficient' : 'Monitoring...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onAllRoomsTap});

  final VoidCallback onAllRoomsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View reset!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F2933),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset View'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAllRoomsTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.grid_view),
            label: const Text('All Rooms'),
          ),
        ),
      ],
    );
  }
}
