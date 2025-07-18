import 'package:geocoding/geocoding.dart'; // Ensure you have geocoding package in pubspec.yaml

/// Utility functions for location-related operations.
class LocationUtils {
  /// Converts latitude and longitude coordinates to a human-readable address string.
  /// Handles null or invalid coordinates gracefully.
  ///
  /// [latitude]: The latitude coordinate.
  /// [longitude]: The longitude coordinate.
  /// Returns a Future that resolves to the address string, or a default message
  /// if coordinates are null or address lookup fails.
  static Future<String> getAddressFromLatLng(
    double? latitude,
    double? longitude,
  ) async {
    // If coordinates are null, return a specific message instead of throwing an error.
    if (latitude == null || longitude == null) {
      return 'Location coordinates not provided';
    }
    try {
      // Attempt to get placemarks from the given coordinates.
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      // If placemarks are found, construct the address.
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Concatenate available address components, filtering out nulls or empty strings.
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
      } else {
        // If no placemarks are found, return a specific message.
        return 'Address not found for coordinates';
      }
    } catch (e) {
      // Catch any errors during the geocoding process and log them.
      print('Error during reverse geocoding: $e');
      // Return a generic error message to the UI.
      return 'Location lookup failed';
    }
  }
}
