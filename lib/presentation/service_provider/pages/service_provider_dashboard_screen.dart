import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_savedprofile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:homeconnect/presentation/service_provider/pages/sp_new_job_requests_screen.dart';

String formatNameFromEmail(String email) {
  final username = email.split('@').first;
  final withSpaces = username.replaceAll(RegExp(r'[._-]'), ' ');
  final words = withSpaces.split(' ');
  return words
      .map(
        (word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
      )
      .join(' ')
      .trim();
}

class ServiceProviderDashboardScreen extends StatefulWidget {
  const ServiceProviderDashboardScreen({super.key});

  @override
  State<ServiceProviderDashboardScreen> createState() =>
      _ServiceProviderDashboardScreenState();
}

class _ServiceProviderDashboardScreenState
    extends State<ServiceProviderDashboardScreen> {
  String providerName = '';
  bool isLoading = true;
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _DashboardContent(providerName: providerName),
      const SpNewJobRequestsScreen(),
      const Center(
        child: Text(
          'Calendar Screen Placeholder',
          style: TextStyle(fontSize: 24),
        ),
      ),
      const Center(
        child: Text('Inbox Screen Placeholder', style: TextStyle(fontSize: 24)),
      ),
    ];
    _fetchProviderName();
    _updateProviderFCMToken();
  }

  Future<void> _fetchProviderName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          providerName = 'Provider';
          isLoading = false;
        });
        _updateDashboardContentWithName();
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('service_providers')
              .doc(user.uid)
              .get();

      String? emailFromFirestore = doc.data()?['email']?.toString();
      String? nameFromFirestore = doc.data()?['fullName']?.toString();

      if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
        setState(() {
          providerName = nameFromFirestore;
          isLoading = false;
        });
      } else if (emailFromFirestore != null && emailFromFirestore.isNotEmpty) {
        setState(() {
          providerName = formatNameFromEmail(emailFromFirestore);
          isLoading = false;
        });
      } else if (user.email != null) {
        setState(() {
          providerName = formatNameFromEmail(user.email!);
          isLoading = false;
        });
      } else {
        setState(() {
          providerName = 'Provider';
          isLoading = false;
        });
      }
      _updateDashboardContentWithName();
    } catch (e) {
      print('Error fetching provider name: $e');
      setState(() {
        providerName = 'Provider';
        isLoading = false;
      });
      _updateDashboardContentWithName();
    }
  }

  void _updateDashboardContentWithName() {
    setState(() {
      _widgetOptions[0] = _DashboardContent(providerName: providerName);
    });
  }

  Future<void> _updateProviderFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Removed _onFabPressed() as the FAB is being removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _widgetOptions.elementAt(_selectedIndex),
      // Removed floatingActionButton
      // Removed floatingActionButtonLocation
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Requests'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF9333EA),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String providerName;

  const _DashboardContent({super.key, required this.providerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E8FF), Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, providerName),
              _buildStatsSummary(),
              _buildProfileManagementSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String providerName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
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
                    '0',
                    'Avg. Rating',
                    Colors.amber,
                  ),
                  _buildStatusItem(
                    Icons.work,
                    '0+',
                    'Jobs Completed',
                    Colors.lightBlueAccent,
                  ),
                  _buildStatusItem(
                    Icons.calendar_today,
                    'Active',
                    'Availability',
                    Colors.greenAccent,
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
      offset: const Offset(0, -32),
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
                  '0',
                  Colors.green,
                ),
                _buildStatRow(
                  Icons.calendar_today_outlined,
                  'Upcoming Jobs',
                  '0',
                  Colors.blue,
                ),
                _buildStatRow(
                  Icons.star_half,
                  'Avg. Rating',
                  '0 (0 reviews)',
                  Colors.amber,
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
            title: 'View saved profile',
            subtitle: 'Like the skills, description, and contact info.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
              );
            },
            colors: const [Color(0xFFFBBF24), Color(0xFFEAB308)],
          ),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.calendar_month,
            title: 'Set Availability',
            subtitle: 'Manage your working hours and days off.',
            onTap: () {
              // TODO: Navigate to Set Availability screen
            },
            colors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.history,
            title: 'View Job History',
            subtitle: 'See all your past completed jobs and earnings.',
            onTap: () {
              // TODO: Navigate to Job History screen
            },
            colors: const [Color(0xFFA855F7), Color(0xFF9333EA)],
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
