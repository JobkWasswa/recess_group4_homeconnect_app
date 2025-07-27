import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/presentation/service_provider/widgets/chat_screen.dart';

class PastBookedProvidersListScreen extends StatefulWidget {
  const PastBookedProvidersListScreen({super.key});

  @override
  State<PastBookedProvidersListScreen> createState() =>
      _PastBookedProvidersListScreenState();
}

class _PastBookedProvidersListScreenState
    extends State<PastBookedProvidersListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late Future<List<ServiceProviderModel>> _bookedProvidersFuture;

  @override
  void initState() {
    super.initState();
    _bookedProvidersFuture = _fetchProvidersFromBookings();
  }

  Future<List<ServiceProviderModel>> _fetchProvidersFromBookings() async {
    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('clientId', isEqualTo: currentUserId)
              .where(
                'status',
                whereIn: [
                  Booking.completed,
                  Booking.completedByProvider,
                  Booking.confirmed,
                ],
              )
              .get();

      final Map<String, ServiceProviderModel> providersMap = {};

      for (var doc in bookingsSnapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        if (booking.serviceProviderId.isNotEmpty &&
            !providersMap.containsKey(booking.serviceProviderId)) {
          providersMap[booking.serviceProviderId] = ServiceProviderModel(
            id: booking.serviceProviderId,
            name: booking.serviceProviderName,
            profilePhoto: null,
            categories: booking.categories,
            rating: 0.0,
            reviewCount: 0,
            distanceKm: null,
            score: 0.0,
            completedJobs: 0,
            email: null,
          );
        }
      }

      return providersMap.values.toList();
    } catch (e) {
      debugPrint('Error fetching providers: $e');
      return [];
    }
  }

  Widget _buildRatingStars(double rating) {
    final stars = List<Widget>.generate(5, (index) {
      return Icon(
        index < rating.round() ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 16,
      );
    });
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 4,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8A80), // Light pink
                  Color(0xFF6A11CB), // Purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          title: const Text(
            'Select Provider to Chat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<ServiceProviderModel>>(
        future: _bookedProvidersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading providers: ${snapshot.error}'),
            );
          }
          final providers = snapshot.data;
          if (providers == null || providers.isEmpty) {
            return const Center(child: Text('No past booked providers found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading:
                      provider.profilePhoto != null
                          ? CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              provider.profilePhoto!,
                            ),
                          )
                          : CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              provider.name.isNotEmpty
                                  ? provider.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                  title: Text(
                    provider.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        provider.categories.isNotEmpty
                            ? provider.categories.join(', ')
                            : 'No categories',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      _buildRatingStars(provider.rating),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                  ),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatScreen(
                              otherUserId: provider.id,
                              otherUserName: provider.name,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
