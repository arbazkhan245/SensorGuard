import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/database_service.dart';
import 'threshold_settings_screen.dart';
import 'history_screen.dart';
import 'smart_home_map_screen.dart';
import 'all_rooms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _autoRefreshInterval = 30; // seconds

  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }

  void _initializeMonitoring() {
    // Start monitoring connectivity
    context.read<ConnectivityProvider>().startMonitoring();
    
    // Fetch location and weather
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LocationProvider>().fetchLocationAndWeather();
      context.read<LocationProvider>().startAutoRefresh();
      
      // Start listening to thresholds first (using default room for now)
      final thresholdProvider = context.read<ThresholdProvider>();
      final alertProvider = context.read<AlertProvider>();
      final tempProvider = context.read<TemperatureProvider>();
      
      thresholdProvider.startListening('default_room');
      
      // Start listening to alerts
      alertProvider.startListening('default_room');
      
      // Update threshold in temperature provider when it changes
      thresholdProvider.addListener(() {
        final threshold = thresholdProvider.getThresholdForRoom('default_room');
        tempProvider.setThreshold(threshold);
      });
      
      // Monitor temperature and create alerts when threshold is exceeded
      tempProvider.startListening();
      tempProvider.addListener(() {
        final latestTemp = tempProvider.getLatestRoomTemperature();
        if (latestTemp != null) {
          final threshold = thresholdProvider.getThresholdForRoom('default_room');
          if (threshold != null && threshold.isBreached(latestTemp)) {
            // Check if alert already exists for this temperature breach
            final existingAlerts = alertProvider.getActiveAlerts('default_room');
            final recentAlert = existingAlerts.isNotEmpty 
                ? existingAlerts.first 
                : null;
            
            // Create alert if no recent alert exists (within last minute)
            if (recentAlert == null || 
                DateTime.now().difference(recentAlert.triggeredAt).inMinutes > 1) {
              final alertType = latestTemp > threshold.maxTemp 
                  ? AlertType.temperatureTooHigh 
                  : AlertType.temperatureTooLow;
              final alert = Alert(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                roomId: 'default_room',
                sensorId: 'realtime_sensor',
                type: alertType,
                temperature: latestTemp,
                threshold: latestTemp > threshold.maxTemp 
                    ? threshold.maxTemp 
                    : threshold.minTemp,
                triggeredAt: DateTime.now(),
                status: AlertStatus.active,
                message: latestTemp > threshold.maxTemp
                    ? 'Temperature ${latestTemp.toStringAsFixed(1)}°C exceeds maximum threshold ${threshold.maxTemp}°C'
                    : 'Temperature ${latestTemp.toStringAsFixed(1)}°C is below minimum threshold ${threshold.minTemp}°C',
                emailSent: false,
                smsSent: false,
              );
              alertProvider.createAlert(alert);
            }
          }
        }
      });
      
      // Start listening to Firestore for historical data
      tempProvider.startListeningToFirestore();
    });
  }

  void _refreshData() {
    context.read<LocationProvider>().fetchLocationAndWeather();
    // Refresh temperature data would be automatic via stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient Header
            _buildHeader(context),
            
            // Connection Status Bar
            _buildConnectionStatusBar(context),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Current Location Card
                    _buildLocationCard(context),
                    const SizedBox(height: 16),
                    
                    // Room Temperature Card
                    _buildRoomTemperatureCard(context),
                    const SizedBox(height: 16),
                    
                    // Outside Temperature Card
                    _buildOutsideTemperatureCard(context),
                    const SizedBox(height: 16),
                    
                    // Today's Readings Card
                    _buildTodaysReadingsCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[600]!,
            Colors.blue[600]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SensorGuard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 4,
            children: [
              _headerIconButton(
                icon: Icons.map,
                tooltip: 'Smart Home Map',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartHomeMapScreen(),
                    ),
                  );
                },
              ),
              _headerIconButton(
                icon: Icons.grid_view,
                tooltip: 'All Rooms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllRoomsScreen(),
                    ),
                  );
                },
              ),
              _headerIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onTap: _refreshData,
              ),
              _headerIconButton(
                icon: Icons.history,
                tooltip: 'History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              _headerIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThresholdSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }

  Widget _buildConnectionStatusBar(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: connectivity.isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connectivity.isConnected
                        ? 'Connected to sensors'
                        : 'Disconnected from sensors',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Auto-refresh: ${_autoRefreshInterval}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final locationDetails = locationProvider.locationDetails;
        
        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.lightBlue[300]!,
                Colors.cyan[400]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (locationProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (locationDetails != null) ...[
                Text(
                  'City: ${locationDetails['city'] ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Latitude: ${locationDetails['latitude'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Longitude: ${locationDetails['longitude'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ] else
                const Text(
                  'Location not available',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomTemperatureCard(BuildContext context) {
    return Consumer2<TemperatureProvider, ThresholdProvider>(
      builder: (context, tempProvider, thresholdProvider, _) {
        final roomTemp = tempProvider.getLatestRoomTemperature();
        final latestReading = tempProvider.latestReadings.values.isEmpty
            ? null
            : tempProvider.latestReadings.values.reduce(
                (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
              );
        
        // Determine status based on threshold
        String status = 'Normal';
        Color statusColor = Colors.green;
        if (latestReading != null) {
          final threshold = thresholdProvider.getThresholdForRoom(latestReading.roomId ?? 'default_room');
          if (threshold != null && threshold.isBreached(latestReading.temperature)) {
            status = 'Critical';
            statusColor = Colors.red;
          } else if (latestReading.temperature > 30) {
            status = 'Warning';
            statusColor = Colors.orange;
          } else if (latestReading.temperature >= 22 && latestReading.temperature <= 25) {
            status = 'Optimal';
            statusColor = Colors.orange;
          } else if (latestReading.temperature >= 18 && latestReading.temperature < 22) {
            status = 'Cool';
            statusColor = Colors.green;
          } else if (latestReading.temperature < 18) {
            status = 'Cold';
            statusColor = Colors.blue;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.thermostat,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Room Temperature',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'Normal' || status == 'Optimal' ? Icons.check : Icons.warning,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (roomTemp != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomTemp.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'No data available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutsideTemperatureCard(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final weatherData = locationProvider.weatherData;

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange[400],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Outside Temperature',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (weatherData != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weatherData['temperature'].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Humidity: ${weatherData['humidity']}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Windspeed: ${weatherData['windspeed'].toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weather: ${weatherData['weather']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ] else if (locationProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                const Text(
                  'Weather data not available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaysReadingsCard(BuildContext context) {
    return Consumer2<TemperatureProvider, ThresholdProvider>(
      builder: (context, tempProvider, thresholdProvider, _) {
        final criticalReadings = tempProvider.getCriticalReadings(
          thresholdProvider.thresholds,
        );
        final todaysReadings = tempProvider.getTodaysReadings();

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Today's Readings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (criticalReadings.isNotEmpty)
                ...criticalReadings.take(5).map((reading) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reading.temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(reading.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Critical',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
              else if (todaysReadings.isNotEmpty)
                ...todaysReadings.take(3).map((reading) {
                  final threshold = thresholdProvider.getThresholdForRoom(reading.roomId ?? 'default_room');
                  final isBreached = threshold != null &&
                      threshold.isBreached(reading.temperature);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isBreached ? Colors.orange[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isBreached ? Colors.orange[200]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBreached ? Icons.warning : Icons.check_circle,
                          color: isBreached ? Colors.orange : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reading.temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(reading.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isBreached)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Text(
                              'Warning',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList()
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No readings available for today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
