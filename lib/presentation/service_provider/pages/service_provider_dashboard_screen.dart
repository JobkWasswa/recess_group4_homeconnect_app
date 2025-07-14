import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_savedprofile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:homeconnect/presentation/service_provider/pages/view_job_request.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProviderName();
    _updateProviderFCMToken();
  }

  // Add to _ServiceProviderDashboardScreenState
  Stream<QuerySnapshot> _getAcceptedJobs() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream<QuerySnapshot>.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: userId)
        .where('status', whereIn: ['confirmed', 'in_progress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('🔥 Firestore error in _getAcceptedJobs: $error');
        });
  }

  Future<void> _fetchProviderName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If no user is logged in, default to 'Provider' and stop loading
        setState(() {
          providerName = 'Provider';
          isLoading = false;
        });
        return;
      }

      String formatNameFromEmail(String email) {
        final namePart = email.split('@').first;
        return namePart
            .replaceAll('.', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
            )
            .join(' ');
      }

      // Attempt to fetch provider data from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('service_providers')
              .doc(user.uid)
              .get();

      String? emailFromFirestore = doc.data()?['email']?.toString();
      String? nameFromFirestore =
          doc
              .data()?['fullName']
              ?.toString(); // Assuming you store a 'fullName' field

      if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
        // Use the 'fullName' from Firestore if available
        setState(() {
          providerName = nameFromFirestore;
          isLoading = false;
        });
      } else if (emailFromFirestore != null && emailFromFirestore.isNotEmpty) {
        // If 'fullName' is not available, try to format from the email stored in Firestore
        setState(() {
          providerName = formatNameFromEmail(emailFromFirestore);
          isLoading = false;
        });
      } else if (user.email != null) {
        // Fallback to formatting from the authenticated user's email
        setState(() {
          providerName = formatNameFromEmail(user.email!);
          isLoading = false;
        });
      } else {
        // Last resort: default to 'Provider'
        setState(() {
          providerName = 'Provider';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching provider name: $e');
      setState(() {
        providerName = 'Provider'; // Fallback in case of any error
        isLoading = false;
      });
    }
  }

  // Save or update FCM token in provider's Firestore document
  Future<void> _updateProviderFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(user.uid)
            .set(
              {'fcmToken': token},
              SetOptions(merge: true),
            ); // Use set with merge to avoid overwriting
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Add this widget method
  Widget _buildActiveJobsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Jobs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _getAcceptedJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No active jobs at the moment.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return Column(
                children:
                    docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildActiveJobCard(context, doc.id, data);
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final categories = data['categories'];
    // Display only the first service if categories is a list, otherwise the whole string or 'Unknown'
    final jobType =
        (categories is List && categories.isNotEmpty)
            ? categories[0]
                .toString() // Take the first item
            : (categories?.toString() ?? 'Unknown');

    final bookingDate = data['bookingDate'];
    final formattedDate =
        bookingDate is Timestamp
            ? bookingDate.toDate().toLocal().toString()
            : 'Unknown date';

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
                Text(
                  data['clientName'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(formattedDate, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .update({
                          'status': 'completed_by_provider',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Job marked as complete!'),
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
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                        _buildActiveJobsSection(context),
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
                    // Notification icon
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
                    // Profile settings icon
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
                    // Logout icon
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
            // Quick Status Summary
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

  Widget _buildJobRequestsSection(BuildContext context) {
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllJobRequestsScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('bookings')
                    .where(
                      'serviceProviderId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No new requests at the moment.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return Column(
                children:
                    docs.take(5).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final categories = data['categories'];
                      // MODIFICATION HERE: Display only the first service
                      final jobType =
                          (categories is List && categories.isNotEmpty)
                              ? categories[0].toString()
                              : (categories?.toString() ?? 'Unknown');

                      final bookingDate = data['bookingDate'];
                      final formattedDate =
                          bookingDate is Timestamp
                              ? bookingDate.toDate().toLocal().toString()
                              : 'Unknown date';
                      final note = data['notes'] ?? '';

                      return _buildJobRequestCard(
                        context: context,
                        jobType:
                            jobType, // This will now only be the first service
                        homeownerName: data['clientName'] ?? 'Unknown',
                        date: formattedDate,
                        location:
                            '', // You can update this from data['location'] if needed
                        price: '', // Add pricing logic if needed
                        bookingId:
                            doc.id, // Pass bookingId for accept/reject actions
                        note: note,
                      );
                    }).toList(),
              );
            },
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
    required String bookingId,
    String? note,
  }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity),
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
                  Expanded(
                    child: Text(
                      homeownerName,
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(color: Colors.grey[700]),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
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
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(bookingId)
                                .update({
                                  'status': 'confirmed',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Job accepted and moved to Active Jobs',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error accepting job: $e'),
                              ),
                            );
                          }
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
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(bookingId)
                                .update({
                                  'status': 'rejected_by_provider',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Rejected $jobType from $homeownerName.',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error rejecting job: $e'),
                              ),
                            );
                          }
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
            colors: const [Color(0xFFFBBF24), Color(0xFFEAB308)], // Yellow
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
            colors: const [Color(0xFF22C55E), Color(0xFF16A34A)], // Green
          ),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.history,
            title: 'View Job History',
            subtitle: 'See all your past completed jobs and earnings.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllJobRequestsScreen()),
              );
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
