import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/presentation/homeowner/pages/profile_display_for_client.dart';
import 'package:homeconnect/data/providers/homeowner_firestore_provider.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceProvidersList extends StatefulWidget {
  final String category;
  final GeoPoint userLocation;
  final DateTime? desiredDateTime;
  static const List<String> activeStatuses = ['pending', 'confirmed'];

  const ServiceProvidersList({
    super.key,
    required this.category,
    required this.userLocation,
    this.desiredDateTime,
  });

  @override
  State<ServiceProvidersList> createState() => _ServiceProvidersListState();
}

class _ServiceProvidersListState extends State<ServiceProvidersList> {
  late Future<List<ServiceProviderModel>> _providersFuture;

  final Map<String, TextEditingController> _notesControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  @override
  void didUpdateWidget(covariant ServiceProvidersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.userLocation != widget.userLocation ||
        oldWidget.desiredDateTime != widget.desiredDateTime) {
      _fetchProviders();
    }
  }

  void _fetchProviders() {
    _providersFuture = HomeownerFirestoreProvider().fetchRecommendedProviders(
      serviceCategory: widget.category,
      homeownerLatitude: widget.userLocation.latitude,
      homeownerLongitude: widget.userLocation.longitude,
      radiusKm: 10.0, // ✅ Set the distance limit here//
      desiredDateTime: widget.desiredDateTime,
    );
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Providers for ${widget.category}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<ServiceProviderModel>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}. Please try again.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No providers found matching your criteria for the selected time.',
              ),
            );
          }

          final providers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              _notesControllers.putIfAbsent(
                provider.id,
                () => TextEditingController(),
              );
              final notesController = _notesControllers[provider.id]!;

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
                                SizedBox(
                                  height: 28,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.blueAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          provider.distanceKm != null
                                              ? '${provider.distanceKm!.toStringAsFixed(1)} km away'
                                              : 'Distance unknown',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 240,
                                child: TextField(
                                  controller: notesController,
                                  decoration: InputDecoration(
                                    hintText: 'Add note for provider',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please log in to book a provider.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final currentUserId = user.uid;
                                    final currentUserName =
                                        user.displayName ?? 'Unknown User';

                                    final providerCategory =
                                        provider.categories.isNotEmpty
                                            ? provider.categories[0]
                                            : '';

                                    // 1. Check for existing active booking in this category
                                    final activeStatuses = [
                                      'pending',
                                      'confirmed',
                                    ];
                                    final existingBookingQuery =
                                        await FirebaseFirestore.instance
                                            .collection('bookings')
                                            .where(
                                              'clientId',
                                              isEqualTo: currentUserId,
                                            )
                                            .where(
                                              'selectedCategory',
                                              isEqualTo: providerCategory,
                                            )
                                            .where(
                                              'status',
                                              whereIn: activeStatuses,
                                            )
                                            .limit(1)
                                            .get();

                                    if (existingBookingQuery.docs.isNotEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You already have an active booking in this category. Please complete or cancel it first.',
                                          ),
                                        ),
                                      );
                                      return; // block booking creation
                                    }

                                    final booking = Booking(
                                      clientId: currentUserId,
                                      clientName: currentUserName,
                                      serviceProviderId: provider.id,
                                      serviceProviderName: provider.name,
                                      categories: provider.categories,
                                      bookingDate: DateTime.now(),
                                      status: 'pending',
                                      selectedCategory:
                                          providerCategory, // ✅ NEW
                                      notes:
                                          notesController
                                              .text, // ✅ Pass user notes here
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                      location:
                                          widget
                                              .userLocation, // <--- Add userLocation here
                                    );

                                    try {
                                      // ✅ Save only once, with Firestore timestamps
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .add(<String, dynamic>{
                                            ...booking.toFirestore(),
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                            'updatedAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Booking sent! Waiting for confirmation.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to book: $e'),
                                        ),
                                      );
                                    }
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

                      FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('bookings')
                                .where(
                                  'clientId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser?.uid,
                                )
                                .where(
                                  'serviceProviderId',
                                  isEqualTo: provider.id,
                                )
                                .where(
                                  'status',
                                  whereIn: ['pending', 'confirmed'],
                                )
                                .limit(1)
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(); // or a small spinner
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox(); // No active booking with this provider
                          }

                          final bookingDoc = snapshot.data!.docs.first;
                          final bookingId = bookingDoc.id;

                          return Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Cancel Booking'),
                                        content: const Text(
                                          'Are you sure you want to cancel this booking?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(bookingId)
                                        .update({
                                          'status': 'cancelled',
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Booking cancelled.'),
                                      ),
                                    );
                                    setState(() {}); // Refresh the UI
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text(
                                'Cancel Booking',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        },
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
