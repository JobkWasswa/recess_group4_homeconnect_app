import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/presentation/homeowner/pages/profile_display_for_client.dart';
import 'package:homeconnect/data/providers/homeowner_firestore_provider.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_calendar.dart';
import 'package:intl/intl.dart';

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
      radiusKm: 10.0,
      desiredDateTime: widget.desiredDateTime,
    );
  }

  Future<int> _getCompletedJobsCount(String providerId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: providerId)
              .where('status', isEqualTo: 'completed')
              .get();
      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting completed jobs count: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Providers for ${widget.category}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ServiceProviderModel>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No providers found'));
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
                                Container(
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
                                const SizedBox(height: 6),
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
                                    '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<int>(
                                future: _getCompletedJobsCount(provider.id),
                                builder: (context, snapshot) {
                                  final count = snapshot.data ?? 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count ${count == 1 ? 'job' : 'jobs'} completed',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
                                width: 120,
                                child: OutlinedButton(
                                  onPressed: () => _handleBookNow(provider),
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
                      _buildActiveBookingButton(provider.id),
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

  Future<void> _handleBookNow(ServiceProviderModel provider) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a provider')),
      );
      return;
    }

    final currentUserName =
        user.displayName ?? (user.email?.split('@')[0] ?? 'Homeowner');
    final providerCategory =
        provider.categories.isNotEmpty ? provider.categories[0] : '';

    final bookingDetails = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder:
            (_) => ServiceProviderCalendarScreen(
              provider: provider,
              category: widget.category,
            ),
      ),
    );

    if (bookingDetails == null) return;

    final DateTime? startDateTime = bookingDetails['startDateTime'];
    final DateTime? endDateTime = bookingDetails['endDateTime'];
    final String? notes = bookingDetails['notes'];
    final bool isFullDay = bookingDetails['isFullDay'] ?? false;

    if (startDateTime == null || endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid date and time')),
      );
      return;
    }

    final startOfDay = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existingBookingsSnapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceProviderId', isEqualTo: provider.id)
            .where('selectedCategory', isEqualTo: providerCategory)
            .where('status', whereIn: ServiceProvidersList.activeStatuses)
            .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
            .where('scheduledDate', isLessThan: endOfDay)
            .get();

    final hasOverlap = existingBookingsSnapshot.docs.any((doc) {
      final data = doc.data();
      final existingStart = (data['scheduledDate'] as Timestamp).toDate();
      final existingEnd = (data['endDateTime'] as Timestamp).toDate();
      return existingStart.isBefore(endDateTime) &&
          existingEnd.isAfter(startDateTime);
    });

    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked for this provider'),
        ),
      );
      return;
    }

    try {
      final booking = Booking(
        clientId: user.uid,
        clientName: currentUserName,
        serviceProviderId: provider.id,
        serviceProviderName: provider.name,
        categories: provider.categories,
        selectedCategory: widget.category,
        bookingDate: DateTime.now(),
        scheduledDate: startDateTime,
        endDateTime: endDateTime,
        scheduledTime: DateFormat.jm().format(startDateTime),
        status: 'pending',
        notes: notes,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        location: widget.userLocation,
        isFullDay: isFullDay, // 👈 Add this line
      );

      final bookingData = booking.toFirestore();
      debugPrint('📝 Booking to Firestore: $bookingData');

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      debugPrint('✅ Booking saved successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking sent! Waiting for confirmation')),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving booking: $e');
      debugPrint('🪵 Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
    }
  }

  Widget _buildActiveBookingButton(String providerId) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('bookings')
              .where(
                'clientId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .where('serviceProviderId', isEqualTo: providerId)
              .where('status', whereIn: ServiceProvidersList.activeStatuses)
              .limit(1)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
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
                      content: const Text('Are you sure you want to cancel?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
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
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled')),
                  );
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    );
  }
}
