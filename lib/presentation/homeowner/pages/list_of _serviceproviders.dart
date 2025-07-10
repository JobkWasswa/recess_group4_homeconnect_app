import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Still needed for GeoPoint or other Firestore related stuff if directly accessing
// May still be useful for client-side location services
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/presentation/homeowner/pages/profile_display_for_client.dart';
import 'package:homeconnect/data/providers/homeowner_firestore_provider.dart'; // Import the updated provider

class ServiceProvidersList extends StatefulWidget {
  final String category;
  final GeoPoint userLocation; // User's current location to pass to the CF

  const ServiceProvidersList({
    super.key,
    required this.category,
    required this.userLocation,
  });

  @override
  State<ServiceProvidersList> createState() => _ServiceProvidersListState();
}

class _ServiceProvidersListState extends State<ServiceProvidersList> {
  late Future<List<ServiceProviderModel>> _providersFuture;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  void _fetchProviders() {
    _providersFuture = HomeownerFirestoreProvider().fetchRecommendedProviders(
      serviceCategory: widget.category,
      homeownerLatitude: widget.userLocation.latitude,
      homeownerLongitude: widget.userLocation.longitude,
      // You can add desiredDateTime here if you implement a date/time picker
      // desiredDateTime: DateTime.now(), // Example
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Providers for ${widget.category}')),
      body: FutureBuilder<List<ServiceProviderModel>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}. Please try again.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No providers found matching your criteria.'),
            );
          }

          final providers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child:
                                provider.profilePhoto != null
                                    ? ClipOval(
                                      child: Image.network(
                                        provider.profilePhoto!,
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
                                  provider.name,
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
                                      provider.distanceKm != null
                                          ? '${provider.distanceKm!.toStringAsFixed(1)} km away'
                                          : 'Distance unknown',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  Text(
                                    '${provider.rating} (${provider.reviewCount} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                ProfileDisplayScreenForClient(
                                                  serviceProviderId:
                                                      provider.id,
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
                                    ),
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
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120,
                                child: OutlinedButton(
                                  onPressed: () {
                                    print(
                                      'Book Now for ${provider.name} (ID: ${provider.id})',
                                    );
                                    // Implement your "Book Now" logic here
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(
                                      color: Colors.purple,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            provider.categories
                                .take(3)
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
                      const SizedBox(height: 10),
                      Text(
                        provider.availableToday
                            ? 'Available today'
                            : 'Unavailable',
                        style: TextStyle(
                          color:
                              provider.availableToday
                                  ? Colors.green
                                  : Colors.red,
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
