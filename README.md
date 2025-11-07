# Sensor Guard

A real-time temperature monitoring application that enables users to monitor room temperatures through a visual interface, set temperature thresholds, receive alerts when thresholds are breached, and view historical temperature data.

## Features

- **Real-time Temperature Monitoring**: Display live temperature data from IoT sensors on a 2D map interface
- **Temperature Thresholds**: Set and manage temperature limits per room with validation (-50°C to 100°C)
- **Alert System**: Receive immediate notifications (in-app, audio) when thresholds are breached
- **Historical Data Analysis**: View temperature trends and statistics for custom time periods
- **Offline Support**: Local caching with Hive enables data access without internet connection
- **Automatic Reconnection**: Firebase reconnection attempts every 30 seconds when offline
- **Cross-Platform**: Works on Android, iOS, Windows, Linux, macOS, and Web

## Project Structure

```
lib/
├── main.dart                 # App entry point with Provider setup
├── models/                   # Data models
│   ├── alert.dart
│   ├── room.dart
│   ├── sensor.dart
│   ├── temperature_reading.dart
│   ├── temperature_threshold.dart
│   └── index.dart
├── services/                 # Backend services
│   ├── firebase_service.dart
│   ├── firebase_options.dart
│   ├── database_service.dart
│   ├── local_cache_service.dart
│   └── notification_service.dart
├── providers/                # State management (Provider)
│   ├── temperature_provider.dart
│   ├── threshold_provider.dart
│   ├── alert_provider.dart
│   ├── connectivity_provider.dart
│   └── index.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── threshold_settings_screen.dart
│   └── history_screen.dart
└── widgets/                  # Reusable widgets
    ├── room_tile.dart
    └── index.dart
```

## Installation

### Prerequisites
- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Firebase project configured

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd SensorGuard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Update `lib/services/firebase_options.dart` with your Firebase credentials
   - Replace placeholder values for each platform (web, android, ios, macos, windows, linux)

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Firebase Setup

1. Create a Firebase Realtime Database project
2. Update `firebase_options.dart` with your project credentials
3. Configure database rules for read/write access:
   ```json
   {
     "rules": {
       "readings": {
         ".read": true,
         ".write": "auth != null"
       },
       "thresholds": {
         ".read": true,
         ".write": "auth != null"
       },
       "alerts": {
         ".read": true,
         ".write": "auth != null"
       },
       "rooms": {
         ".read": true,
         ".write": "auth != null"
       },
       "sensors": {
         ".read": true,
         ".write": "auth != null"
       }
     }
   }
   ```

## Architecture

### Data Flow

1. **Firebase Database** → Temperature data, thresholds, alerts
2. **DatabaseService** → Real-time data synchronization and CRUD operations
3. **LocalCacheService** (Hive) → Offline data storage and retrieval
4. **Providers** → State management and business logic
5. **UI Screens** → User interface consuming provider data

### Service Layer

- **FirebaseService**: Initializes Firebase with platform-specific configuration
- **DatabaseService**: Handles all Firebase Realtime Database operations with offline persistence
- **LocalCacheService**: Manages Hive boxes for local data caching
- **NotificationService**: Manages in-app and audio notifications

### State Management (Provider Pattern)

- **TemperatureProvider**: Manages real-time temperature readings
- **ThresholdProvider**: Handles threshold configuration with validation
- **AlertProvider**: Monitors and manages temperature alerts
- **ConnectivityProvider**: Tracks Firebase connection status and handles reconnection

## Key Features Implementation

### Real-time Monitoring
- Streams from Firebase update UI within 5 seconds
- 2D map visualization shows temperature with color coding
- Recent readings displayed in list format

### Temperature Thresholds
- Valid range: -50°C to 100°C
- Per-room configuration stored in Firebase
- Validation prevents invalid inputs

### Alert System
- Triggers when temperature exceeds/falls below threshold
- Multiple notification methods: in-app, audio
- Alert tracking with status: active, acknowledged, resolved

### Historical Data
- Supports time ranges: 1 hour to 1 year
- Statistics: average, min, max temperature
- Data table with timestamp and sensor information

### Offline Support
- Automatic local caching with Hive
- Connection status indicator
- Automatic reconnection attempts every 30 seconds
- Seamless sync when connection restored

## Dependencies

- **firebase_core**: Firebase initialization
- **firebase_database**: Real-time database operations
- **provider**: State management
- **hive** & **hive_flutter**: Local data persistence
- **flutter_local_notifications**: Push notifications
- **audioplayers**: Audio alert playback
- **fl_chart**: Chart visualization (future enhancement)
- **intl**: Date/time formatting
- **shared_preferences**: User preferences

## API Documentation

### DatabaseService

```dart
// Temperature readings
Future<void> saveTemperatureReading(TemperatureReading reading)
Stream<List<TemperatureReading>> getLatestReadings(String roomId)

// Thresholds
Future<void> setThreshold(TemperatureThreshold threshold)
Stream<TemperatureThreshold?> getThreshold(String roomId)

// Alerts
Future<void> createAlert(Alert alert)
Stream<List<Alert>> getActiveAlerts(String roomId)
Future<void> updateAlert(Alert alert)

// Connectivity
Stream<bool> getConnectionStatus()
Future<void> goOnline()
Future<void> goOffline()
```

### Providers

```dart
// TemperatureProvider
Map<String, TemperatureReading> get latestReadings
void startListening(String roomId)
Future<void> addTemperatureReading(TemperatureReading reading)

// ThresholdProvider
Future<void> setThreshold(String roomId, double minTemp, double maxTemp)
TemperatureThreshold? getThresholdForRoom(String roomId)
bool isValidThreshold(double minTemp, double maxTemp)

// AlertProvider
List<Alert> getAlertsForRoom(String roomId)
Future<void> createAlert(Alert alert)
Future<void> acknowledgeAlert(String alertId, String roomId)

// ConnectivityProvider
bool get isConnected
void startMonitoring()
```

## Future Enhancements

- Email and SMS alert integration
- Advanced charting with fl_chart
- User authentication with Firebase Auth
- Role-based access control (admin, facility manager, analyst)
- Real-time multi-user collaboration
- Mobile app responsive design improvements
- Sensor pairing and management interface
- Alert history and reporting
- Mobile push notifications (Firebase Cloud Messaging)

## Testing

To test the application:

1. Create sample temperature data in Firebase
2. Set thresholds and verify alerts trigger
3. Test offline mode by disconnecting network
4. Verify data syncs when connection restored

## Troubleshooting

### Firebase Connection Issues
- Verify Firebase credentials in `firebase_options.dart`
- Check Firebase database rules allow read/write access
- Ensure internet connection is active

### Notifications Not Showing
- Check notification permissions on device
- Verify audio file exists at `assets/sounds/alert.mp3`
- Check app is not in focus for background notifications

### Data Not Syncing
- Verify Hive boxes are initialized
- Check Firebase connection status in app
- Manually trigger reconnection from connectivity monitor

## License

Private project - All rights reserved

## Support

For issues or questions, please contact the development team.
#   S e n s o r G u a r d  
 