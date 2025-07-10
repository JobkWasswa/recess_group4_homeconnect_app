import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/users.dart'; // CHANGE: Import UserProfile model
import 'package:geolocator/geolocator.dart';
import 'package:homeconnect/presentation/homeowner/pages/list_of _serviceproviders.dart';
//import 'package:geolocator/geolocator.dart';

// Helper – convert something like “john_doe99@example.com” → “John Doe99”
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                _buildRecommendedProfessionalsSection(context),
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
                                () => print('Homeowner Notifications pressed'),
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
                        onPressed: () => print('Homeowner Profile pressed'),
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
                        print('❌ Error: $e');
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

  Widget _buildRecommendedProfessionalsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Professionals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildProfessionalCard(
                context: context,
                name: 'Grace Nakato',
                service: 'Plumbing Expert',
                rating: '4.9',
                jobsCompleted: '150+',
                imageUrl: 'https://via.placeholder.com/150',
              ),
              const SizedBox(height: 10),
              _buildProfessionalCard(
                context: context,
                name: 'David Ssenyonga',
                service: 'Electrical & AC Repair',
                rating: '4.7',
                jobsCompleted: '120+',
                imageUrl: 'https://via.placeholder.com/150',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard({
    required BuildContext context,
    required String name,
    required String service,
    required String rating,
    required String jobsCompleted,
    required String imageUrl,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          print('Professional tapped: \$name');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on \$name\'s profile!')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      service,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 16),
                        Text(
                          '\$rating (\$jobsCompleted jobs)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingStatusSection(BuildContext context) {
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
          _buildBookingStatusCard(
            context: context,
            service: 'Plumbing Repair',
            provider: 'Grace Nakato',
            status: 'Pending',
            date: 'Tomorrow, 10:00 AM',
            statusColor: Colors.orange,
          ),
          const SizedBox(height: 10),
          _buildBookingStatusCard(
            context: context,
            service: 'House Cleaning',
            provider: 'CleanSweep Ltd.',
            status: 'Confirmed',
            date: 'Today, 2:00 PM',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                print('View All Bookings pressed');
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
    required String date,
    required Color statusColor,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          print('Booking tapped: \$service with \$provider');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on booking for \$service!')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'With: \$provider',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
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
              print('My Bookings bottom nav pressed!');
            },
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.work),
            color: Colors.grey,
            onPressed: () {
              print('My Jobs bottom nav pressed!');
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
