import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Make sure geolocator is added to your pubspec.yaml
import 'package:homeconnect/presentation/homeowner/pages/profile_display_for_client.dart';

class ServiceProvidersList extends StatelessWidget {
  final String category;
  final GeoPoint userLocation;

  const ServiceProvidersList({
    super.key,
    required this.category,
    required this.userLocation,
  });

  // Safely handle mixed GeoPoint / Map input
  static GeoPoint? _extractGeoPoint(dynamic locationData) {
    if (locationData is GeoPoint) {
      return locationData;
    } else if (locationData is Map<String, dynamic> &&
        locationData.containsKey('latitude') &&
        locationData.containsKey('longitude')) {
      return GeoPoint(
        (locationData['latitude'] as num).toDouble(),
        (locationData['longitude'] as num).toDouble(),
      );
    }
    return null;
  }

  Future<List<DocumentSnapshot>> _fetchProviders(GeoPoint userLocation) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('service_providers')
              .where('categories', arrayContains: category)
              .get();

      final providers = snapshot.docs;

      // Sort by distance
      providers.sort((a, b) {
        GeoPoint? locA = _extractGeoPoint(a['location']);
        GeoPoint? locB = _extractGeoPoint(b['location']);

        if (locA == null || locB == null) return 0;

        final distanceA = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          locA.latitude,
          locA.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          locB.latitude,
          locB.longitude,
        );

        return distanceA.compareTo(distanceB);
      });

      return providers;
    } catch (e) {
      print('❌ Firestore fetch error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Providers for $category')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchProviders(userLocation),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No providers found.'));
          }

          final providers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final data = providers[index].data() as Map<String, dynamic>;
              final docId = providers[index].id;

              final name = data['name'] ?? 'Unnamed';
              final availableToday = data['availableToday'] ?? false;
              final categories = List<String>.from(data['categories'] ?? []);
              final profilePhoto = data['profilePhoto'];
              final providerLocation = _extractGeoPoint(data['location']);
              final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
              final int reviewCount = data['reviewCount'] ?? 0;

              double? distanceKm;
              if (providerLocation != null) {
                final distanceInMeters = Geolocator.distanceBetween(
                  userLocation.latitude,
                  userLocation.longitude,
                  providerLocation.latitude,
                  providerLocation.longitude,
                );
                distanceKm = distanceInMeters / 1000;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align items to the top
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child:
                                profilePhoto != null
                                    ? ClipOval(
                                      child: Image.network(
                                        profilePhoto,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stack) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                ),
                                      ),
                                    )
                                    : const Icon(Icons.person, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distanceKm != null
                                          ? '${distanceKm.toStringAsFixed(1)} km away'
                                          : 'Distance unknown',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                // Moved available/unavailable to the bottom
                              ],
                            ),
                          ),
                          // Right-aligned section for rating and buttons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize:
                                    MainAxisSize.min, // To keep the row compact
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  Text(
                                    '$rating (${reviewCount} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120, // Consistent width for buttons
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                ProfileDisplayScreenForClient(
                                                  serviceProviderId: docId,
                                                ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ), // Adjust padding
                                  ),
                                  child: const Text(
                                    'View Profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ), // Spacing between buttons
                              SizedBox(
                                width: 120, // Consistent width for buttons
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Implement your "Book Now" logic here
                                    print('Book Now for $name (ID: $docId)');
                                    // You might navigate to a booking screen, show a dialog, etc.
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Colors.purple, // Text color
                                    side: const BorderSide(
                                      color: Colors.purple,
                                    ), // Border color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ), // Adjust padding
                                  ),
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Skills/Categories chips (MOVED HERE)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            categories
                                .take(3) // Limit to first 3 categories
                                .map(
                                  (cat) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      cat,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 10), // Spacing before availability
                      // Availability/Unavailable (MOVED HERE)
                      Text(
                        availableToday ? 'Available today' : 'Unavailable',
                        style: TextStyle(
                          color: availableToday ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
