import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:homeconnect/data/models/users.dart';
//import 'package:homeconnect/data/models/booking.dart';

String nameFromEmail(String email) {
  final localPart = email.split('@').first;
  final words = localPart.split(RegExp(r'[._]'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class HomeownerDashboardScreen extends StatefulWidget {
  final UserProfile? profile;
  const HomeownerDashboardScreen({super.key, this.profile});

  @override
  State<HomeownerDashboardScreen> createState() =>
      _HomeownerDashboardScreenState();
}

class _HomeownerDashboardScreenState extends State<HomeownerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Booking> _pendingBookings = [];
  List<Booking> _confirmedBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _fetchBookings() {
    setState(() {
      _pendingBookings = [
        Booking(
          id: 'b1',
          serviceName: 'Plumbing Repair',
          providerName: 'Grace Nakato',
          status: 'Pending',
          date: 'Tomorrow, 10:00 AM',
          providerId: 'sp1',
        ),
      ];
      _confirmedBookings = [
        Booking(
          id: 'b2',
          serviceName: 'House Cleaning',
          providerName: 'CleanSweep Ltd.',
          status: 'Confirmed',
          date: 'Today, 2:00 PM',
          providerId: 'sp2',
        ),
      ];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showRatingPopup(String serviceProviderId, String providerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double currentRating = 0.0;
        return AlertDialog(
          title: Text('Rate $providerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How would you rate the service provided by $providerName?'),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            currentRating = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentRating > 0) {
                  debugPrint('User rated $providerName $currentRating stars.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for rating $providerName!'),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit Rating'),
            ),
          ],
        );
      },
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
            colors: [Color(0xFFF0F9FF), Color(0xFFFFFFFF), Color(0xFFFEF2F2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(context),
                buildSearchAndFilter(),
                buildCategorySection(context),
                buildPopularServicesSection(context),
                _buildBookingStatusSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => debugPrint('Post a new job pressed!'),
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.email != null ? nameFromEmail(user!.email!) : 'User';

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
                    _buildHeaderIconButton(
                      icon: Icons.notifications,
                      onPressed: () => debugPrint('Notifications pressed'),
                      hasNotification: true,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconButton(
                      icon: Icons.person,
                      onPressed: () => debugPrint('Profile pressed'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconButton(
                      icon: Icons.logout,
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.auth);
                        }
                      },
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

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
          ),
          if (hasNotification)
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
    );
  }

  Widget buildSearchAndFilter() {
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

  Widget buildCategorySection(BuildContext context) {
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
                      final pos = await _determinePosition();
                      if (pos == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location is required.'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AppRoutes.serviceProviderListPage,
                        arguments: {
                          'category': category['name'],
                          'location': GeoPoint(pos.latitude, pos.longitude),
                        },
                      );
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

  Widget buildPopularServicesSection(BuildContext context) {
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
                        debugPrint(
                          'Popular service tapped: ${service['name']}',
                        );
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
                                          debugPrint(
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
          if (_pendingBookings.isEmpty && _confirmedBookings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'You have no active bookings yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          if (_pendingBookings.isNotEmpty) ...[
            const Text(
              'Pending Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._pendingBookings.map(
              (booking) => _buildBookingStatusCard(
                context: context,
                service: booking.serviceName,
                provider: booking.providerName,
                status: booking.status,
                date: booking.date,
                statusColor: Colors.orange,
                isCompleted: false,
                bookingId: booking.id,
                providerId: booking.providerId,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_confirmedBookings.isNotEmpty) ...[
            const Text(
              'Confirmed Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._confirmedBookings.map(
              (booking) => _buildBookingStatusCard(
                context: context,
                service: booking.serviceName,
                provider: booking.providerName,
                status: booking.status,
                date: booking.date,
                statusColor: Colors.green,
                isCompleted: true,
                bookingId: booking.id,
                providerId: booking.providerId,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: TextButton(
              onPressed: () => debugPrint('View All Bookings pressed'),
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
    required bool isCompleted,
    required String bookingId,
    required String providerId,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          debugPrint('Booking tapped: $service with $provider');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on booking for $service!')),
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
                'With: $provider',
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
              if (isCompleted)
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton.icon(
                    onPressed: () => showRatingPopup(providerId, provider),
                    icon: Icon(Icons.star_rate, color: Colors.amber[700]),
                    label: const Text(
                      'Rate Service',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
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
            onPressed: () => debugPrint('My Bookings bottom nav pressed!'),
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.work),
            color: Colors.grey,
            onPressed: () => debugPrint('My Jobs bottom nav pressed!'),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            color: Colors.grey,
            onPressed: () => debugPrint('Messages bottom nav pressed!'),
          ),
        ],
      ),
    );
  }
}
