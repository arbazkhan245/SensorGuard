import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class DatabaseService {
  late final FirebaseDatabase _realtimeDatabase;
  late final FirebaseFirestore _firestore;

  DatabaseService() {
    _realtimeDatabase = FirebaseDatabase.instance;
    _realtimeDatabase.setPersistenceEnabled(true);
    _firestore = FirebaseFirestore.instance;
  }

  // Read real-time sensor data from Firebase Realtime Database
  Stream<double?> getRealtimeTemperature() {
    return _realtimeDatabase
        .ref('Temperature')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      
      // Handle both string and number types
      if (data is num) {
        return data.toDouble();
      } else if (data is String) {
        return double.tryParse(data);
      }
      return null;
    });
  }

  // Save temperature reading to Firestore sensor_data collection
  Future<void> saveTemperatureReading(TemperatureReading reading) async {
    try {
      await _firestore.collection('sensor_data').add(reading.toJson());
    } catch (e) {
      throw Exception('Failed to save temperature reading to Firestore: $e');
    }
  }

  // Get latest readings from Firestore sensor_data collection
  Stream<List<TemperatureReading>> getLatestReadings({int limit = 100}) {
    return _firestore
        .collection('sensor_data')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TemperatureReading.fromJson(data, doc.id);
      }).toList();
    });
  }

  // Get today's readings from Firestore
  Future<List<TemperatureReading>> getTodaysReadings() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      final snapshot = await _firestore
          .collection('sensor_data')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDayStr)
          .where('timestamp', isLessThan: endOfDayStr)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TemperatureReading.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      // If query fails (e.g., no index), get all and filter in memory
      try {
        final snapshot = await _firestore
            .collection('sensor_data')
            .orderBy('timestamp', descending: true)
            .limit(1000)
            .get();

        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return TemperatureReading.fromJson(data, doc.id);
        }).where((reading) {
          return reading.timestamp.isAfter(startOfDay) && 
                 reading.timestamp.isBefore(endOfDay);
        }).toList();
      } catch (e2) {
        throw Exception('Failed to get today\'s readings: $e2');
      }
    }
  }

  // Get historical data from Firestore
  Future<List<TemperatureReading>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();

      final snapshot = await _firestore
          .collection('sensor_data')
          .where('timestamp', isGreaterThanOrEqualTo: startDateStr)
          .where('timestamp', isLessThan: endDateStr)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TemperatureReading.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      // If query fails (e.g., no index), get all and filter in memory
      try {
        final snapshot = await _firestore
            .collection('sensor_data')
            .orderBy('timestamp', descending: true)
            .limit(5000)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return TemperatureReading.fromJson(data, doc.id);
        }).where((reading) {
          return reading.timestamp.isAfter(startDate) && 
                 reading.timestamp.isBefore(endDate);
        }).toList();
      } catch (e2) {
        throw Exception('Failed to get historical data: $e2');
      }
    }
  }

  // Get readings where alert was triggered
  Stream<List<TemperatureReading>> getAlertReadings() {
    return _firestore
        .collection('sensor_data')
        .where('alert_triggered', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TemperatureReading.fromJson(data, doc.id);
      }).toList();
    });
  }

  // Threshold Operations (using Firestore)
  Future<void> setThreshold(TemperatureThreshold threshold) async {
    try {
      await _firestore
          .collection('thresholds')
          .doc(threshold.id)
          .set(threshold.toJson());
    } catch (e) {
      throw Exception('Failed to set threshold: $e');
    }
  }

  Stream<TemperatureThreshold?> getThreshold(String roomId) {
    return _firestore
        .collection('thresholds')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Get the most recent threshold
      final thresholds = snapshot.docs.map((doc) {
        try {
          return TemperatureThreshold.fromJson(doc.data());
        } catch (e) {
          return null;
        }
      }).whereType<TemperatureThreshold>().toList();
      
      if (thresholds.isEmpty) return null;
      thresholds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return thresholds.first;
    });
  }

  Future<TemperatureThreshold?> getThresholdOnce(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('thresholds')
          .where('roomId', isEqualTo: roomId)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return TemperatureThreshold.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get threshold: $e');
    }
  }

  // Alert Operations (using Firestore)
  Future<void> createAlert(Alert alert) async {
    try {
      await _firestore.collection('alerts').doc(alert.id).set(alert.toJson());
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  Stream<List<Alert>> getActiveAlerts(String roomId) {
    return _firestore
        .collection('alerts')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .where((alert) => alert.status == AlertStatus.active)
          .toList();
    });
  }

  Future<void> updateAlert(Alert alert) async {
    try {
      await _firestore.collection('alerts').doc(alert.id).update(alert.toJson());
    } catch (e) {
      throw Exception('Failed to update alert: $e');
    }
  }

  // Update sensor_data document to mark alert_triggered
  Future<void> updateSensorDataAlert(String docId, bool alertTriggered) async {
    try {
      await _firestore
          .collection('sensor_data')
          .doc(docId)
          .update({'alert_triggered': alertTriggered});
    } catch (e) {
      throw Exception('Failed to update sensor data alert: $e');
    }
  }

  // Room Operations (using Firestore)
  Future<void> saveRoom(Room room) async {
    try {
      await _firestore.collection('rooms').doc(room.id).set(room.toJson());
    } catch (e) {
      throw Exception('Failed to save room: $e');
    }
  }

  Stream<List<Room>> getAllRooms() {
    return _firestore.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Room.fromJson(doc.data()))
          .toList();
    });
  }

  Future<List<Room>> getAllRoomsOnce() async {
    try {
      final snapshot = await _firestore.collection('rooms').get();
      return snapshot.docs.map((doc) => Room.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get rooms: $e');
    }
  }

  // Sensor Operations (using Firestore)
  Future<void> saveSensor(Sensor sensor) async {
    try {
      await _firestore
          .collection('sensors')
          .doc(sensor.id)
          .set(sensor.toJson());
    } catch (e) {
      throw Exception('Failed to save sensor: $e');
    }
  }

  Stream<List<Sensor>> getSensorsForRoom(String roomId) {
    return _firestore
        .collection('sensors')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Sensor.fromJson(doc.data())).toList();
    });
  }

  // Connection Management (Realtime Database)
  Future<void> goOffline() async {
    await _realtimeDatabase.goOffline();
  }

  Future<void> goOnline() async {
    await _realtimeDatabase.goOnline();
  }

  Stream<bool> getConnectionStatus() {
    return _realtimeDatabase.ref('.info/connected').onValue.map((event) {
      final isConnected = event.snapshot.value as bool?;
      return isConnected ?? false;
    });
  }
}
