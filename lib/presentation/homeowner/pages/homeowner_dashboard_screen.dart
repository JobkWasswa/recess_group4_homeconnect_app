import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/users.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homeconnect/presentation/homeowner/pages/list_of _serviceproviders.dart';

import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/presentation/homeowner/pages/view_all_bookings.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Helper – convert something like “john_doe99@example.com” → “John”
String nameFromEmail(String email) {
  final localPart = email.split('@').first;
  final words = localPart.split(RegExp(r'[._]'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class HomeownerDashboardScreen extends StatefulWidget {
  final UserProfile? profile; // CHANGE: Add profile parameter
  const HomeownerDashboardScreen({super.key, this.profile});

  @override
  State<HomeownerDashboardScreen> createState() =>
      _HomeownerDashboardScreenState();
}

class _HomeownerDashboardScreenState extends State<HomeownerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Add to _HomeownerDashboardScreenState
  Stream<QuerySnapshot> _getCompletableJobs() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed_by_provider')
        .snapshots();
  }

  // ★ ADDED: Request permission and fetch GPS coordinates
  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  String _formatDate(DateTime date) {
    // Format like: Tomorrow, 10:00 AM or Monday, 3:00 PM
    final now = DateTime.now();
    final isTomorrow = date.difference(now).inDays == 1;
    final isToday = date.day == now.day;

    final time = TimeOfDay.fromDateTime(date).format(context); // ✅ correct here

    if (isToday) return 'Today, $time';
    if (isTomorrow) return 'Tomorrow, $time';

    return '${_weekdayName(date.weekday)}, $time';
  }

  String _weekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'denied':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Add thi
  Widget _buildVerificationCard(BuildContext context, Booking booking) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.categories.isNotEmpty ? booking.categories[0] : 'Service',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  booking.serviceProviderName,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDate(booking.bookingDate),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  double selectedRating = 3.0;
                  final TextEditingController feedbackController =
                      TextEditingController();

                  // Prevent duplicate rating
                  final ratingDoc =
                      await FirebaseFirestore.instance
                          .collection('ratings')
                          .where('bookingId', isEqualTo: booking.bookingId)
                          .limit(1)
                          .get();

                  if (ratingDoc.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You already rated this job.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Rate Service Provider'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RatingBar.builder(
                              initialRating: 3,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemBuilder:
                                  (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                              onRatingUpdate: (rating) {
                                selectedRating = rating;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: feedbackController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Leave a comment (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              try {
                                // Update booking status
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(booking.bookingId)
                                    .update({
                                      'status': 'completed',
                                      'completedAt':
                                          FieldValue.serverTimestamp(),
                                    });

                                // Add rating to 'ratings' collection
                                await FirebaseFirestore.instance
                                    .collection('ratings')
                                    .add({
                                      'bookingId': booking.bookingId,
                                      'providerId': booking.serviceProviderId,
                                      'clientId': booking.clientId,
                                      'rating': selectedRating,
                                      'review': feedbackController.text.trim(),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                // Update average rating of provider
                                final providerRef = FirebaseFirestore.instance
                                    .collection('service_providers')
                                    .doc(booking.serviceProviderId);

                                final providerDoc = await providerRef.get();
                                final currentRating =
                                    providerDoc.data()?['averageRating'] ?? 0.0;
                                final reviewCount =
                                    providerDoc.data()?['numberOfReviews'] ?? 0;

                                final newTotalRating =
                                    (currentRating * reviewCount) +
                                    selectedRating;
                                final newReviewCount = reviewCount + 1;
                                final newAvgRating =
                                    newTotalRating / newReviewCount;

                                await providerRef.update({
                                  'averageRating': newAvgRating,
                                  'numberOfReviews': newReviewCount,
                                  'completedJobs': FieldValue.increment(1),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Rating submitted and job verified!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Submit Rating'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Verify Job Completion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF), // blue-50
              Color(0xFFFFFFFF), // white
              Color(0xFFFEF2F2), // red-50
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSearchAndFilter(),
                _buildCategorySection(context),
                _buildPopularServicesSection(context),
                _buildBookingStatusSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Post a new job pressed!');
          // Navigator.of(context).pushNamed(AppRoutes.postJobScreen);
        },
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user != null && user.email != null
            ? nameFromEmail(user.email!)
            : 'User';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.purple[100], fontSize: 14),
                    ),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed:
                                () => debugPrint(
                                  'Homeowner Notifications pressed',
                                ),
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed:
                            () => debugPrint('Homeowner Profile pressed'),
                        icon: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.auth);
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) async {
                if (value.isEmpty) return;
                final pos = await _determinePosition();
                if (pos == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location is required.')),
                  );
                  return;
                }
                Navigator.of(context).pushNamed(
                  AppRoutes.serviceProviderListPage,
                  arguments: {
                    'query': value,
                    'location': GeoPoint(pos.latitude, pos.longitude),
                  },
                );
              },
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final text = _searchController.text;
                if (text.isEmpty) return;
                final pos = await _determinePosition();
                if (pos == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location is required.')),
                  );
                  return;
                }
                Navigator.of(context).pushNamed(
                  AppRoutes.serviceProviderListPage,
                  arguments: {
                    'query': text,
                    'location': GeoPoint(pos.latitude, pos.longitude),
                  },
                );
              },
              icon: const Icon(Icons.search),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      {'name': 'Roof Cleaning', 'image': 'lib/assets/images/roof_cleaning.png'},
      {
        'name': 'Compound Cleaning',
        'image': 'lib/assets/images/compound_cleaning.jpg',
      },
      {'name': 'Painting', 'image': 'lib/assets/images/painting.png'},
      {
        'name': 'House Cleaning',
        'image': 'lib/assets/images/house_cleaning.jpg',
      },
      {'name': 'Laundry & Ironing', 'image': 'lib/assets/images/laundry.png'},
      {
        'name': 'Cooking & Dish Washing',
        'image': 'lib/assets/images/cooking.jpg',
      },
      {'name': 'Babysitting', 'image': 'lib/assets/images/babysitting.png'},
      {'name': 'Gardening', 'image': 'lib/assets/images/gardening.jpg'},
      {
        'name': 'Furniture Repair',
        'image': 'lib/assets/images/furn_repair.png',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      try {
                        // Step 1: Check if location services are enabled
                        bool serviceEnabled =
                            await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          throw Exception('Location services are disabled.');
                        }

                        // Step 2: Check permission and request if necessary
                        LocationPermission permission =
                            await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                          if (permission == LocationPermission.denied) {
                            throw Exception('Location permission was denied.');
                          }
                        }

                        // Step 3: Handle deniedForever — guide user to settings
                        if (permission == LocationPermission.deniedForever) {
                          // Show dialog to help user fix it
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text('Location Permission Required'),
                                  content: Text(
                                    'To get service providers near your current location, please enable location permission in your phone settings.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Geolocator.openAppSettings();
                                      },
                                      child: Text('Open Settings'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text('Cancel'),
                                    ),
                                  ],
                                ),
                          );
                          return; // stop here
                        }

                        // ✅ Step 4: Always get new location on tap
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                            accuracy: LocationAccuracy.best,
                          ),
                        );

                        // Step 5: Save location in Firestore
                        final userId = FirebaseAuth.instance.currentUser!.uid;
                        final docRef = FirebaseFirestore.instance
                            .collection('homeowners')
                            .doc(userId);
                        final doc = await docRef.get();

                        if (doc.exists) {
                          await docRef.update({
                            'location': GeoPoint(pos.latitude, pos.longitude),
                          });
                        } else {
                          await docRef.set({
                            'location': GeoPoint(pos.latitude, pos.longitude),
                          });
                        }

                        // Step 6: Navigate to provider list with new location
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => ServiceProvidersList(
                                  category: category['name']!,
                                  userLocation: GeoPoint(
                                    pos.latitude,
                                    pos.longitude,
                                  ),
                                ),
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ Error: $e');
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },

                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.asset(
                            category['image']!,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: const Text(
                                  'Explore',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesSection(BuildContext context) {
    final popularServices = [
      {
        'name': 'Painting',
        'duration': 'Full day',
        'description': 'Professional wall painting services',
        'image': 'lib/assets/images/painting2.png',
      },
      {
        'name': 'Compound Cleaning',
        'duration': '3-6 hours',
        'description': 'Thorough cleaning of outdoor spaces',
        'image': 'lib/assets/images/compound_cleaning3.jpg',
      },
      {
        'name': 'House Cleaning',
        'duration': '4-8 hours',
        'description': 'Deep cleaning for residential properties',
        'image': 'lib/assets/images/furn_moving.png',
      },
      {
        'name': 'Interior Painting',
        'duration': '1-3 days',
        'description': 'Transform your indoor spaces with a fresh coat',
        'image': 'lib/assets/images/painting2.png',
      },
      {
        'name': 'Custom Furniture',
        'duration': '1-2 weeks',
        'description': 'Handcrafted custom furniture and cabinetry',
        'image': 'lib/assets/images/furn_moving.png',
      },
      {
        'name': 'Furniture Repair',
        'duration': '2-5 hours',
        'description': 'Repair and restoration of existing furniture',
        'image': 'lib/assets/images/furn_repair.png',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularServices.length,
              itemBuilder: (context, index) {
                final service = popularServices[index];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 15),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        print('Popular service tapped: ${service['name']}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tapped on ${service['name']}!'),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Stack(
                              children: [
                                Image.asset(
                                  service['image']!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          print(
                                            'Quick View for ${service['name']}',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove_red_eye,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Quick View',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['name']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      service['duration']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  service['description']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Replace _buildBookingStatusSection with this
  Widget _buildBookingStatusSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Please log in to view your bookings.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Verification Requests Section
          StreamBuilder<QuerySnapshot>(
            stream: _getCompletableJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children:
                          docs.map((doc) {
                            return _buildVerificationCard(
                              context,
                              Booking.fromFirestore(doc),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox();
            },
          ),

          // Regular Bookings Section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('clientId', isEqualTo: user.uid)
                .where('status', whereIn: ['pending', 'confirmed'])
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots()
                .handleError((error) {
                  debugPrint('🔥 Firestore error: $error');
                }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('You have no bookings yet.');
              }

              final bookings =
                  snapshot.data!.docs
                      .map((doc) => Booking.fromFirestore(doc))
                      .toList();

              return Column(
                children:
                    bookings.map((booking) {
                      final statusColor = _getStatusColor(booking.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            _buildBookingStatusCard(
                              context: context,
                              service:
                                  booking.selectedCategory.isNotEmpty
                                      ? booking.selectedCategory
                                      : 'No category',
                              provider: booking.serviceProviderName,
                              status: capitalize(booking.status.toString()),
                              booking: booking,
                              statusColor: statusColor,
                            ),
                            if (booking.status.toLowerCase() == 'denied')
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ServiceProvidersList(
                                                category:
                                                    booking
                                                            .categories
                                                            .isNotEmpty
                                                        ? booking.categories[0]
                                                        : '',
                                                userLocation: booking.location,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Book Another',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllBookingsScreen()),
                );
              },
              child: const Text('View All My Bookings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusCard({
    required BuildContext context,
    required String service,
    required String provider,
    required String status,
    required Booking booking,
    required Color statusColor,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          print('Booking tapped: $service with $provider');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on booking for $service!')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Title (e.g., "Plumbing")
              Text(
                service,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              // Service Provider Name
              Text(
                'Provider: $provider',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              // Booking Dates
              Text(
                'Booked on: ${_formatDate(booking.bookingDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              if (booking.scheduledDate != null)
                Text(
                  'Scheduled for: ${_formatDate(booking.scheduledDate!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              const SizedBox(height: 6),
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            color: Colors.purple[700],
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: Colors.grey,
            onPressed: () {
              debugPrint('My Bookings bottom nav pressed!');
            },
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.work),
            color: Colors.grey,
            onPressed: () {
              debugPrint('My Jobs bottom nav pressed!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            color: Colors.grey,
            onPressed: () {
              print('Messages bottom nav pressed!');
            },
          ),
        ],
      ),
    );
  }
}
