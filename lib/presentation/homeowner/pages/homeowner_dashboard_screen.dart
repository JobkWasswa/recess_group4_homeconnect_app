import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart'; // Ensure this is imported for navigation
import 'package:firebase_auth/firebase_auth.dart'; // NEW: to get current user

// Helper – convert something like “john_doe99@example.com” → “John Doe99”
String nameFromEmail(String email) {
  final localPart = email.split('@').first; // before "@"
  final words = localPart.split(RegExp(r'[._]')); // split on "." or "_"
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class HomeownerDashboardScreen extends StatelessWidget {
  const HomeownerDashboardScreen({Key? key}) : super(key: key);

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
          // TODO: Navigate to Post a Job screen
          print('Post a new job pressed!');
        },
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context) {
    // NEW: derive friendly name from current user's email
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
                      displayName, // dynamic name
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
                              // TODO: Navigate to Notifications
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
                          // TODO: Navigate to Profile Settings
                          print('Homeowner Profile pressed');
                        },
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
                        onPressed: () {
                          // Logout: Navigate back to Auth screen
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.auth);
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
                // TODO: Open filter options
                print('Filter button pressed!');
              },
              icon: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final categories = [
                {'name': 'Plumbing', 'icon': Icons.plumbing},
                {'name': 'Electrical', 'icon': Icons.electrical_services},
                {'name': 'Cleaning', 'icon': Icons.cleaning_services},
                {'name': 'Carpentry', 'icon': Icons.carpenter},
                {'name': 'Painting', 'icon': Icons.format_paint},
                {'name': 'Gardening', 'icon': Icons.local_florist},
              ];
              final category = categories[index];
              return _buildCategoryCard(
                context,
                category['name'] as String,
                category['icon'] as IconData,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          print('Category tapped: $title');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on $title category!')));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.purple[700]),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularServicesSection(BuildContext context) {
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
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final services = [
                  {
                    'name': 'Deep Cleaning',
                    'provider': 'CleanSweep Ltd.',
                    'rating': '4.9',
                    'price': 'UGX 50,000',
                  },
                  {
                    'name': 'AC Repair',
                    'provider': 'Cool Air Pros',
                    'rating': '4.7',
                    'price': 'UGX 80,000',
                  },
                  {
                    'name': 'Wall Painting',
                    'provider': 'Artistic Walls',
                    'rating': '4.8',
                    'price': 'UGX 100,000',
                  },
                  {
                    'name': 'Pipe Leak Fix',
                    'provider': 'Aqua Solutions',
                    'rating': '4.9',
                    'price': 'UGX 45,000',
                  },
                  {
                    'name': 'Garden Landscaping',
                    'provider': 'Green Thumb',
                    'rating': '4.6',
                    'price': 'UGX 120,000',
                  },
                ];
                final service = services[index];
                return _buildServiceCard(
                  context: context,
                  serviceName: service['name'] as String,
                  providerName: service['provider'] as String,
                  rating: service['rating'] as String,
                  price: service['price'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String serviceName,
    required String providerName,
    required String rating,
    required String price,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            print('Service tapped: $serviceName');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped on $serviceName by $providerName!'),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    image: const DecorationImage(
                      image: NetworkImage('https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  providerName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 16),
                    Text(
                      rating,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
          print('Professional tapped: $name');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on $name\'s profile!')),
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
                          '$rating ($jobsCompleted jobs)',
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
