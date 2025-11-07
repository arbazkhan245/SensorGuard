import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/firebase_service.dart';
import 'services/database_service.dart';
import 'services/local_cache_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'services/weather_service.dart';
import 'providers/index.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize local cache
  final localCache = LocalCacheService();
  await localCache.initializeBoxes();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<LocalCacheService>(create: (_) => localCache),
        Provider<NotificationService>(create: (_) => notificationService),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<WeatherService>(create: (_) => WeatherService()),
        // Providers
        ChangeNotifierProvider(
          create: (context) => TemperatureProvider(
            databaseService: context.read<DatabaseService>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ThresholdProvider(
            databaseService: context.read<DatabaseService>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AlertProvider(
            databaseService: context.read<DatabaseService>(),
            cacheService: context.read<LocalCacheService>(),
            notificationService: context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ConnectivityProvider(
            databaseService: context.read<DatabaseService>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(
            locationService: context.read<LocationService>(),
            weatherService: context.read<WeatherService>(),
          ),
        ),
      ],
      child: const SensorGuardApp(),
    ),
  );
}

class SensorGuardApp extends StatelessWidget {
  const SensorGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Guard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
