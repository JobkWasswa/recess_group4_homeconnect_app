import 'package:geocoding/geocoding.dart';

/// Utility functions for location-related operations.
class LocationUtils {
  /// Converts latitude and longitude coordinates to a human-readable address string.
  /// Handles null or invalid coordinates gracefully.
  ///
  /// IMPORTANT: For this function to work in a web environment, you need to ensure
  /// that your `index.html` file (in `web/index.html`) includes the Google Maps
  /// JavaScript API with a valid API key.
  /// Example in index.html <head>:
  /// <script async defer src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=places"></script>
  /// Replace 'YOUR_API_KEY_HERE' with your actual Google Maps API Key.
  /// Also, ensure your API key is properly restricted (e.g., by HTTP referrer for web apps).
  ///
  /// [latitude]: The latitude coordinate.
  /// [longitude]: The longitude coordinate.
  /// Returns a Future that resolves to the address string, or a default message
  /// if coordinates are null or address lookup fails.
  static Future<String> getAddressFromLatLng(
    double? latitude,
    double? longitude,
  ) async {
    if (latitude == null || longitude == null) {
      return 'Location coordinates not provided';
    }
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
      } else {
        return 'Address not found for coordinates';
      }
    } catch (e) {
      print('Error during reverse geocoding: $e');
      return 'Location lookup failed';
    }
  }
}
