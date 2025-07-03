import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart'; // Import routes for logout navigation
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_savedprofile.dart';

class ServiceProviderDashboardScreen extends StatefulWidget {
  const ServiceProviderDashboardScreen({super.key});

  @override
  State<ServiceProviderDashboardScreen> createState() =>
      _ServiceProviderDashboardScreenState();
}

class _ServiceProviderDashboardScreenState
    extends State<ServiceProviderDashboardScreen> {
  String providerName = '';
  String _userProfession = ''; // To store the service provider's profession
  double _starRating = 1.0; // Default: one star rating
  int _jobsCompleted = 0; // Default: zero jobs completed
  String _availabilityStatus = 'Active'; // Default: active

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  String _formatNameFromEmail(String email) {
    final username = email.split('@').first;
    // Replace dots, underscores, and dashes with spaces
    final withSpaces = username.replaceAll(RegExp(r'[._-]'), ' ');
    // Capitalize each word
    final words = withSpaces.split(' ');
    final capitalizedWords = words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
    return capitalizedWords.trim();
  }

  Future<void> _fetchProviderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          providerName = 'Provider';
          isLoading = false;
        });
        return;
      }
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = doc.data();
      final email =
          data != null && data['email'] != null
              ? data['email'].toString()
              : null;
      final profession =
          data != null && data['profession'] != null
              ? data['profession'].toString()
              : ''; // Fetch profession

      setState(() {
        providerName = email != null ? _formatNameFromEmail(email) : 'Provider';
        _userProfession = profession; // Set the fetched profession
        // Initialize or fetch actual rating/jobs from Firestore if available
        // For now, using default values as per requirement 1
        _starRating = (data?['starRating'] as num?)?.toDouble() ?? 1.0;
        _jobsCompleted = (data?['jobsCompleted'] as int?) ?? 0;
        _availabilityStatus =
            (data?['availabilityStatus'] as String?) ?? 'Active';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        providerName = 'Provider';
        _userProfession = ''; // Default profession on error
        _starRating = 1.0;
        _jobsCompleted = 0;
        _availabilityStatus = 'Active';
        isLoading = false;
      });
      print('Error fetching provider data: $e');
    }
  }

  // Simulate updating availability status
  void _updateAvailabilityStatus(String newStatus) {
    setState(() {
      _availabilityStatus = newStatus;
    });
    // In a real app, you would update this in Firestore
    // FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
    //   'availabilityStatus': newStatus,
    // });
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
              Color(0xFFF3E8FF), // purple-50
              Color(0xFFFFFFFF), // white
              Color(0xFFE0F2FE), // blue-50
            ],
          ),
        ),
        child: SafeArea(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildStatsSummary(),
                        _buildJobRequestsSection(context),
                        _buildProfileManagementSection(context),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9333EA), Color(0xFFEC4899)], // Purple to Pink
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
                      'Hello,',
                      style: TextStyle(color: Colors.purple[100], fontSize: 14),
                    ),
                    Text(
                      providerName,
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
                              print('Provider Notifications pressed');
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
                          print('Provider Profile pressed');
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
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
            const SizedBox(height: 24),
            // Quick Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem(
                    Icons.star,
                    _starRating.toStringAsFixed(1), // Display dynamic rating
                    'Avg. Rating',
                    Colors.amber,
                  ),
                  _buildStatusItem(
                    Icons.work,
                    _jobsCompleted.toString(), // Display dynamic jobs completed
                    'Jobs Completed',
                    Colors.lightBlueAccent,
                  ),
                  _buildStatusItem(
                    Icons.calendar_today,
                    _availabilityStatus, // Display dynamic availability status
                    'Availability',
                    _availabilityStatus == 'Active'
                        ? Colors.greenAccent
                        : Colors.orangeAccent, // Change color based on status
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Transform.translate(
      offset: const Offset(0, -32), // Pull up into the header gradient
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  Icons.check_circle_outline,
                  'Completed Jobs',
                  _jobsCompleted.toString(), // Use dynamic value
                  Colors.green,
                ),
                _buildStatRow(
                  Icons.calendar_today_outlined,
                  'Upcoming Jobs',
                  '0', // This can be dynamic too if you fetch it
                  Colors.blue,
                ),
                _buildStatRow(
                  Icons.star_half,
                  'Avg. Rating',
                  '${_starRating.toStringAsFixed(1)} (0 reviews)', // Use dynamic value
                  Colors.amber,
                ),
                _buildStatRow(
                  Icons.monetization_on,
                  'Earnings (last 30 days)',
                  'UGX 0', // This should be dynamic
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Simulated list of all job requests (replace with actual Firestore fetch)
  final List<Map<String, String>> _allJobRequests = [
    {
      'jobType': 'House Cleaning',
      'profession': 'Cleaner',
      'homeownerName': 'Sarah K.',
      'date': 'Today, 2:00 PM',
      'location': 'Ntinda',
      'price': 'UGX 20,000',
    },
    {
      'jobType': 'Plumbing Fix',
      'profession': 'Plumber',
      'homeownerName': 'Alex M.',
      'date': 'Tomorrow, 10:00 AM',
      'location': 'Kansanga',
      'price': 'UGX 35,000',
    },
    {
      'jobType': 'Electrical Wiring',
      'profession': 'Electrician',
      'homeownerName': 'John D.',
      'date': 'Friday, 9:00 AM',
      'location': 'Muyenga',
      'price': 'UGX 50,000',
    },
    {
      'jobType': 'Deep Cleaning',
      'profession': 'Cleaner',
      'homeownerName': 'Alice G.',
      'date': 'Tomorrow, 3:00 PM',
      'location': 'Bugolobi',
      'price': 'UGX 40,000',
    },
  ];

  // Function to filter job requests based on the provider's profession
  List<Map<String, String>> _getFilteredJobRequests(String profession) {
    if (profession.isEmpty) {
      return [];
    }
    return _allJobRequests
        .where((job) => job['profession'] == profession)
        .toList();
  }

  Widget _buildJobRequestsSection(BuildContext context) {
    final filteredJobs = _getFilteredJobRequests(_userProfession);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Job Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to All Job Requests screen, possibly passing the profession
                  print(
                    'View All Requests pressed for profession: $_userProfession',
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredJobs.isEmpty)
            Center(
              child: Text(
                'No new requests for your profession ($_userProfession) at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children:
                  filteredJobs
                      .map(
                        (job) => _buildJobRequestCard(
                          context: context,
                          jobType: job['jobType']!,
                          homeownerName: job['homeownerName']!,
                          date: job['date']!,
                          location: job['location']!,
                          price: job['price']!,
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobRequestCard({
    required BuildContext context,
    required String jobType,
    required String homeownerName,
    required String date,
    required String location,
    required String price,
  }) {
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
              jobType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(homeownerName, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(date, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(location, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        print(
                          'Accept button pressed for $jobType from $homeownerName',
                        );
                        _updateAvailabilityStatus(
                          'Booked',
                        ); // Change status to Booked
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Accepted $jobType from $homeownerName! Your status is now Booked.',
                            ),
                          ),
                        );
                        // In a real app, you would also update job status in Firestore
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        print(
                          'Reject button pressed for $jobType from $homeownerName',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rejected $jobType from $homeownerName.',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[400]!),
                        foregroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileManagementSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Your Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            icon: Icons.edit,
            title: 'View saved proflie',
            subtitle: 'Like the skills, description, and contact info.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
              );
            },
            colors: const [Color(0xFFFBBF24), Color(0xFFEAB308)], // Yellow
          ),
          const SizedBox(height: 12),
          // Removed 'Set Availability' as per requirement 3
          // _buildManagementCard(
          //   context: context,
          //   icon: Icons.calendar_month,
          //   title: 'Set Availability',
          //   subtitle: 'Manage your working hours and days off.',
          //   onTap: () {
          //     print('Set Availability pressed');
          //   },
          //   colors: const [Color(0xFF22C55E), Color(0xFF16A34A)], // Green
          // ),
          // const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.history,
            title: 'View Job History',
            subtitle: 'See all your past completed jobs and earnings.',
            onTap: () {
              // TODO: Navigate to Job History screen
              print('View Job History pressed');
            },
            colors: const [Color(0xFFA855F7), Color(0xFF9333EA)], // Purple
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> colors,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors[0].withOpacity(0.1), colors[1].withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}
