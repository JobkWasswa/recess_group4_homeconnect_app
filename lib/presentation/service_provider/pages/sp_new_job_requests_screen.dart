import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpNewJobRequestsScreen extends StatelessWidget {
  const SpNewJobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Job Requests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(
          0xFF9333EA,
        ), // Match the dashboard header color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'serviceProviderId',
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )
                  .orderBy(
                    'createdAt',
                    descending: true,
                  ) // Ensure 'createdAt' field exists and is a Timestamp
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              // Display the error for debugging, especially permission denied errors
              return Center(
                child: Text(
                  'Error: ${snapshot.error}\nPlease check Firestore rules and indexes.',
                ),
              );
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
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                return _buildJobRequestCard(
                  context: context,
                  jobType: data['categories'] ?? 'Unknown',
                  homeownerName: data['clientName'] ?? 'Unknown',
                  date:
                      (data['bookingDate'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString(),
                  location: data['location'] ?? 'Not specified',
                  price:
                      data['price']?.toString() ??
                      'N/A', // Display price if available, else N/A
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobRequestCard({
    required BuildContext context,
    required String jobType,
    required String homeownerName,
    required String date,
    required String location,
    required String price, // Added price back
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Price: $price',
                  style: TextStyle(color: Colors.grey[700]),
                ), // Display price
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print(
                      'Accept button pressed for $jobType from $homeownerName',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Accepted $jobType from $homeownerName!'),
                      ),
                    );
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
                        content: Text('Rejected $jobType from $homeownerName.'),
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
      ),
    );
  }
}
