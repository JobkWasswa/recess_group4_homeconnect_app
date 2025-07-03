import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
//import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Checks if location services are enabled and requests permission if needed
  static Future<bool> _checkLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        // You might want to open app settings here to allow manual permission enabling
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      return false;
    }
  }

  /// Gets the current device location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        debugPrint('No location permissions granted');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Calculates distance between two points in kilometers
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
            startLatitude,
            startLongitude,
            endLatitude,
            endLongitude,
          ) /
          1000; // Convert meters to kilometers
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return -1; // Return invalid distance to indicate error
    }
  }

  /// Gets the approximate address from coordinates
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final addressParts =
            [
              place.street,
              place.subLocality,
              place.locality,
              place.postalCode,
              place.country,
            ].where((part) => part?.isNotEmpty ?? false).toList();

        return addressParts.join(', ');
      }
      debugPrint('No placemarks found for coordinates');
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }
}
