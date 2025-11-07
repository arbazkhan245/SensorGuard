import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../services/notification_service.dart';

class ThresholdSettingsScreen extends StatefulWidget {
  const ThresholdSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThresholdSettingsScreen> createState() =>
      _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends State<ThresholdSettingsScreen> {
  double _minTemp = -5.0;
  double _maxTemp = 40.0;
  bool _pushNotifications = true;
  bool _hapticFeedback = true;
  bool _autoRefresh = true;
  int _refreshInterval = 30;
  bool _locationServices = true;
  String _temperatureUnit = '°C';

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  void _loadThresholds() {
    final provider = context.read<ThresholdProvider>();
    final threshold = provider.getThresholdForRoom('default_room');
    if (threshold != null) {
      setState(() {
        _minTemp = threshold.minTemp;
        _maxTemp = threshold.maxTemp;
      });
    }
  }

  void _saveThreshold() async {
    final provider = context.read<ThresholdProvider>();
    final notificationService = context.read<NotificationService>();
    await provider.setThreshold('default_room', _minTemp, _maxTemp);
    
    if (mounted) {
      if (provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threshold saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await notificationService.showSimpleNotification(
          'Threshold Updated',
          'New range: ${_minTemp.toStringAsFixed(1)}° - ${_maxTemp.toStringAsFixed(1)}°',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetSettings() {
    setState(() {
      _minTemp = -5.0;
      _maxTemp = 40.0;
      _pushNotifications = true;
      _hapticFeedback = true;
      _autoRefresh = true;
      _refreshInterval = 30;
      _locationServices = true;
      _temperatureUnit = '°C';
    });
    _saveThreshold();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FDFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications', Icons.notifications, const Color(0xFF008080)),
          _buildToggleTile(
            'Push Notifications',
            'Receive weather alerts and updates',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
          ),
          _buildToggleTile(
            'Haptic Feedback',
            'Feel vibrations for interactions',
            _hapticFeedback,
            (value) => setState(() => _hapticFeedback = value),
          ),
          
          const SizedBox(height: 24),
          
          // Data & Sync Section
          _buildSectionHeader('Data & Sync', Icons.sync, const Color(0xFF008080)),
          _buildToggleTile(
            'Auto Refresh',
            'Automatically update weather data',
            _autoRefresh,
            (value) => setState(() => _autoRefresh = value),
          ),
          _buildSliderTile(
            'Refresh Interval',
            '$_refreshInterval seconds',
            _refreshInterval.toDouble(),
            10,
            300,
            (value) => setState(() => _refreshInterval = value.toInt()),
          ),
          _buildToggleTile(
            'Location Services',
            'Use GPS for accurate weather data',
            _locationServices,
            (value) => setState(() => _locationServices = value),
          ),
          
          const SizedBox(height: 24),
          
          // Temperature Section
          _buildSectionHeader('Temperature', Icons.thermostat, const Color(0xFF008080)),
          _buildTemperatureUnitSelector(),
          _buildSliderTile(
            'Min Threshold',
            '${_minTemp.toStringAsFixed(1)} $_temperatureUnit',
            _minTemp,
            -50,
            50,
            (value) => setState(() => _minTemp = value),
          ),
          _buildSliderTile(
            'Max Threshold',
            '${_maxTemp.toStringAsFixed(1)} $_temperatureUnit',
            _maxTemp,
            -50,
            50,
            (value) => setState(() => _maxTemp = value),
          ),
          
          const SizedBox(height: 24),
          
          // Data Management Section
          _buildSectionHeader('Data Management', Icons.list, const Color(0xFF008080)),
          _buildActionTile(
            'Reset Settings',
            'Reset all settings to default',
            Icons.refresh,
            _resetSettings,
          ),
          
          const SizedBox(height: 32),
          
          // Save Button
          ElevatedButton(
            onPressed: _saveThreshold,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text(
              'Save Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 32, color: Color(0xFF008080)),
                const SizedBox(height: 8),
                const Text(
                  'SensorGuard v1.0.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008080),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Built with Flutter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF008080),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, String value, double currentValue, double min, double max, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008080),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: currentValue,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: const Color(0xFF008080),
            inactiveColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureUnitSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temperature Unit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Display temperatures in ${_temperatureUnit == '°C' ? 'Celsius' : 'Fahrenheit'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUnitButton('°C', _temperatureUnit == '°C'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitButton('°F', _temperatureUnit == '°F'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _temperatureUnit = unit),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF008080) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF008080)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
