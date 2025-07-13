import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllJobRequestsScreen extends StatelessWidget {
  const AllJobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Job Requests'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('bookings')
                .where('serviceProviderId', isEqualTo: userId)
                // Uncomment below to exclude completed/cancelled jobs:
                // .where('status', whereNotIn: ['completed_by_provider', 'cancelled'])
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
            return const Center(
              child: Text(
                'No job requests available.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final categories = data['categories'];
              final jobType =
                  (categories is List && categories.isNotEmpty)
                      ? categories[0].toString()
                      : 'Unknown';

              final bookingDate = data['bookingDate'];
              final formattedDate =
                  bookingDate is Timestamp
                      ? bookingDate.toDate().toLocal().toString()
                      : 'Unknown date';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(jobType),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${data['clientName'] ?? 'Unknown'}'),
                      Text('Date: $formattedDate'),
                      Text('Status: ${data['status']}'),
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
}
