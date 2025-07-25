// File: homeconnect/presentation/homeowner/pages/all_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/data/models/booking.dart';

class AllBookingsScreen extends StatelessWidget {
  const AllBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your bookings.')),
      );
    }

    final currentUserId = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('All My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('clientId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .handleError((error) {
              // 👇 This will help you detect missing index errors in debug console
              print('🔥 Firestore error (AllBookingsScreen): $error');
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          print("Current user ID: $currentUserId");

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no bookings.'));
          }

          final bookings =
              snapshot.data!.docs
                  .map((doc) => Booking.fromFirestore(doc))
                  .toList();

          return ListView.builder(
            itemCount: bookings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    booking.serviceProviderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${booking.categories.join(", ")}\n${booking.status.toUpperCase()} • ${booking.bookingDate.toLocal().toString().substring(0, 16)}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    Icons.circle,
                    size: 14,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'denied':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
