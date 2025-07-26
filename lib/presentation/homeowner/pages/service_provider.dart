import 'package:cloud_firestore/cloud_firestore.dart'; // Import for DocumentSnapshot and GeoPoint

class ServiceProvider {
  final String id;
  final String name;
  final String
  specialty; // Based on your previous error, if this is a List<String>, update it here.
  final String? profilePictureUrl;
  final double rating;
  final int completedJobs;
  final LatLng location; // Your custom LatLng class
  final bool isAvailable;
  final String profession;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.profilePictureUrl,
    required this.rating,
    required this.completedJobs,
    required this.location,
    required this.isAvailable,
    required this.profession,
  });

  // This is the factory constructor needed for Firestore DocumentSnapshot
  factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle GeoPoint to LatLng conversion
    GeoPoint geoPoint = data['location'] as GeoPoint;
    LatLng serviceLocation = LatLng(geoPoint.latitude, geoPoint.longitude);

    return ServiceProvider(
      id: doc.id, // Get document ID directly from doc
      name: data['name'] ?? '',
      specialty:
          data['specialty'] ??
          '', // Assuming it's a String. If it's a List, handle accordingly.
      profilePictureUrl: data['profilePictureUrl'],
      // Safely convert to double. 'num' covers both int and double from Firestore.
      rating:
          (data['rating'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      completedJobs:
          (data['completedJobs'] as int?) ?? 0, // Default to 0 if null
      location: serviceLocation, // Use the converted LatLng
      isAvailable: data['isAvailable'] ?? true,
      profession: data['profession'] ?? '',
    );
  }

  // You can keep this if you also need to parse from generic JSON maps (e.g., from an API)
  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      profilePictureUrl: json['profilePictureUrl'],
      rating:
          (json['rating'] as num?)?.toDouble() ??
          0.0, // Safely convert num to double
      completedJobs: (json['completedJobs'] as int?) ?? 0,
      location: LatLng(
        (json['location'] as Map<String, dynamic>)['latitude'] as double,
        (json['location'] as Map<String, dynamic>)['longitude'] as double,
      ), // Assuming location is a nested map in generic JSON
      isAvailable: json['isAvailable'] ?? true,
      profession: json['profession'],
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
