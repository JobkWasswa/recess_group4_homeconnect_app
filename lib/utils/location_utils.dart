// lib/utils/location_utils.dart

import 'package:geocoding/geocoding.dart'; // Make sure you have this package in pubspec.yaml

/// Converts latitude and longitude coordinates into a human-readable address.
/// Handles null coordinates gracefully.
Future<String> getAddressFromLatLng(double? lat, double? lng) async {
  if (lat == null || lng == null) {
    return "Location not available"; // Handle null case gracefully
  }
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      // Customize the address format as needed. Example:
      // return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      return "${place.street}, ${place.locality}, ${place.country}"; // Simpler format
    }
    return "Address not found";
  } catch (e) {
    print("Error during reverse geocoding: $e");
    return "Error getting address";
  }
}
