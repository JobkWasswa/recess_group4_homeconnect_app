class ServiceProvider {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int completedJobs;
  final LatLng location;
  final bool isAvailable;
  final String profession;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.completedJobs,
    required this.location,
    required this.isAvailable,
    required this.profession,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      rating: json['rating']?.toDouble() ?? 1.0,
      completedJobs: json['completedJobs'] ?? 0,
      location: LatLng(json['lat'], json['lng']),
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
