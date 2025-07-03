import 'package:flutter/material.dart';
//import 'package:homeconnect/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:homeconnect/data/models/users.dart'; // Import UserProfile model
import 'package:homeconnect/data/models/users.dart';
//import 'package:homeconnect/presentation/service_provider/pages/service_provider_profile.dart'; // Assuming you have a ServiceProvider model
//import 'package:homeconnect/data/models/booking.dart'; // Assuming you have a Booking model

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
  final UserProfile? profile; // Add profile parameter
  const HomeownerDashboardScreen({super.key, this.profile});

  @override
  State<HomeownerDashboardScreen> createState() =>
      _HomeownerDashboardScreenState();
}

class _HomeownerDashboardScreenState extends State<HomeownerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for bookings to simulate pending and confirmed services
  // In a real app, you would fetch this from a backend
  List<Booking> _pendingBookings = [];
  List<Booking> _confirmedBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings(); // Simulate fetching bookings on init
  }

  void _fetchBookings() {
    // This is mock data. In a real application, you would
    // fetch this from a database (e.g., Firebase, your backend API)
    setState(() {
      _pendingBookings = [
        Booking(
          id: 'b1',
          serviceName: 'Plumbing Repair',
          providerName: 'Grace Nakato',
          status: 'Pending',
          date: 'Tomorrow, 10:00 AM',
          providerId: 'sp1', // Example provider ID
        ),
      ];
      _confirmedBookings = [
        Booking(
          id: 'b2',
          serviceName: 'House Cleaning',
          providerName: 'CleanSweep Ltd.',
          status: 'Confirmed',
          date: 'Today, 2:00 PM',
          providerId: 'sp2', // Example provider ID
        ),
      ];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRatingPopup(String serviceProviderId, String providerName) {
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentRating > 0) {
                  // TODO: Implement logic to update the service provider's rating
                  // This would typically involve sending the rating to your backend
                  print('User rated $providerName $currentRating stars.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for rating $providerName!'),
                    ),
                  );
                  // Simulate updating the provider's dashboard (in a real app, this would be backend logic)
                  // For now, just print a confirmation
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
                _buildSearchAndFilter(), // Will pass profile internally
                _buildCategorySection(context),
                _buildPopularServicesSection(context),
                // _buildRecommendedProfessionalsSection(context), // REMOVED as per requirement 3
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
          // TODO: Navigate to Post a Job screen
          print('Post a new job pressed!');
          // Example: Navigator.of(context).pushNamed(AppRoutes.postJobScreen);
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
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Purple to Pink
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
                            onPressed: () {
                              print('Homeowner Notifications pressed');
                            },
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
                        onPressed: () {
                          print('Homeowner Profile pressed');
                        },
                        icon: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          25,
                        ), // Corrected from 'Fielding:'
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
              readOnly: true, // Make it read-only to act as a button
              onTap: () {
                // Feature 1: Navigate to recommended service providers on search bar tap
                Navigator.of(context).pushNamed(
                  AppRoutes.serviceProviderListPage,
                  arguments: {
                    'query':
                        _searchController.text.isNotEmpty
                            ? _searchController.text
                            : null,
                    'location': widget.profile?.location ?? 'Kampala',
                    'recommendationCriteria':
                        true, // Indicate that recommendations are needed
                  },
                );
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  // This is for actual search submission, but onTap handles the initial navigation
                  Navigator.of(context).pushNamed(
                    AppRoutes.serviceProviderListPage,
                    arguments: {
                      'query': value,
                      'location': widget.profile?.location ?? 'Kampala',
                    },
                  );
                }
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
              onPressed: () {
                // Feature 1: Navigate to recommended service providers on search icon tap
                Navigator.of(context).pushNamed(
                  AppRoutes.serviceProviderListPage,
                  arguments: {
                    'query':
                        _searchController.text.isNotEmpty
                            ? _searchController.text
                            : null,
                    'location': widget.profile?.location ?? 'Kampala',
                    'recommendationCriteria':
                        true, // Indicate that recommendations are needed
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
                return _buildExploreCategoryCard(
                  context,
                  category['name'] as String,
                  category['image'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCategoryCard(
    BuildContext context,
    String title,
    String imageUrl,
  ) {
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
        onTap: () {
          // Feature 2: Navigate to selected category service providers
          print('Category tapped: $title');
          Navigator.of(context).pushNamed(
            AppRoutes.serviceProviderListPage,
            arguments: {
              'category': title,
              'location': widget.profile?.location ?? 'Kampala',
              'recommendationCriteria':
                  true, // Indicate recommendations for category
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
                imageUrl,
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
                    title,
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
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                return _buildPopularServiceCard(
                  context: context,
                  serviceName: service['name'] as String,
                  duration: service['duration'] as String,
                  description: service['description'] as String,
                  imageUrl: service['image'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServiceCard({
    required BuildContext context,
    required String serviceName,
    required String duration,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 15),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Feature 2: Navigate to selected popular service providers
            print('Popular service tapped: $serviceName');
            Navigator.of(context).pushNamed(
              AppRoutes.serviceProviderListPage,
              arguments: {
                'service': serviceName,
                'location': widget.profile?.location ?? 'Kampala',
                'recommendationCriteria':
                    true, // Indicate recommendations for popular service
              },
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
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                              print('Quick View for $serviceName');
                              // TODO: Implement quick view logic
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
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      serviceName,
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
                          duration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
  }

  // Removed _buildRecommendedProfessionalsSection as per requirement 3

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
          // Display Pending Services
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
                isCompleted: false, // Mark as not completed
                bookingId: booking.id,
                providerId: booking.providerId,
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Display Confirmed Services
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
                isCompleted: true, // Mark as completed for demonstration
                bookingId: booking.id,
                providerId: booking.providerId,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: TextButton(
              onPressed: () {
                print('View All Bookings pressed');
                // TODO: Navigate to a dedicated "My Bookings" page
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
    required bool isCompleted, // Added to trigger rating pop-up
    required String bookingId,
    required String providerId,
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
              if (isCompleted) // Feature 4: Show rate button if service is "completed"
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _showRatingPopup(providerId, provider);
                      // In a real app, you'd remove this booking from confirmed once rated
                      // or mark it as 'rated' to prevent multiple ratings
                    },
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
            onPressed: () {
              print('My Bookings bottom nav pressed!');
            },
          ),
          const SizedBox(width: 48), // Space for the FAB
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

// Dummy models for demonstration purposes. You should replace these with your actual models.

class ServiceProvider {
  final String id;
  final String name;
  final String service;
  final double rating;
  final int jobsCompleted;
  final String imageUrl;
  final String location;
  final bool isAvailable;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.service,
    required this.rating,
    required this.jobsCompleted,
    required this.imageUrl,
    required this.location,
    required this.isAvailable,
  });
}

class Booking {
  final String id;
  final String serviceName;
  final String providerName;
  final String status;
  final String date;
  final String providerId;

  Booking({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.status,
    required this.date,
    required this.providerId,
  });
}

// Dummy AppRoutes for navigation. Ensure these match your actual route definitions.
class AppRoutes {
  static const String auth = '/auth';
  static const String serviceProviderListPage = '/serviceProviderList';
}
