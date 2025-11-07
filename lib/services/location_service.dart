import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<Map<String, String>> getLocationDetails(Position position) async {
    try {
      // Get placemarks from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'city': place.locality ?? place.subAdministrativeArea ?? 'Unknown',
          'country': place.country ?? 'Unknown',
          'latitude': position.latitude.toStringAsFixed(4),
          'longitude': position.longitude.toStringAsFixed(4),
        };
      }

      return {
        'city': 'Unknown',
        'country': 'Unknown',
        'latitude': position.latitude.toStringAsFixed(4),
        'longitude': position.longitude.toStringAsFixed(4),
      };
    } catch (e) {
      print('Error getting location details: $e');
      return {
        'city': 'Unknown',
        'country': 'Unknown',
        'latitude': position.latitude.toStringAsFixed(4),
        'longitude': position.longitude.toStringAsFixed(4),
      };
    }
  }
}

