import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homeconnect/data/models/booking.dart'; // Ensure this path is correct
import 'package:homeconnect/utils/location_utils.dart'; // Ensure this path is correct

class ProviderCalendarScreen extends StatefulWidget {
  const ProviderCalendarScreen({super.key});

  @override
  State<ProviderCalendarScreen> createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends State<ProviderCalendarScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Appointments'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Please log in to view your appointments.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('bookings')
                .where('serviceProviderId', isEqualTo: currentUser.uid)
                .where('status', whereIn: ['confirmed', 'in_progress'])
                .orderBy(
                  'scheduledDate',
                  descending: false,
                ) // Order by scheduled date
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No upcoming or active appointments.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          final List<Booking> appointments =
              snapshot.data!.docs.map((doc) {
                return Booking.fromFirestore(doc);
              }).toList();

          // Group appointments by date for better display
          final Map<DateTime, List<Booking>> groupedAppointments = {};
          for (var booking in appointments) {
            if (booking.scheduledDate != null) {
              // Normalize date to remove time component for grouping
              final DateTime dateOnly = DateTime(
                booking.scheduledDate!.year,
                booking.scheduledDate!.month,
                booking.scheduledDate!.day,
              );
              if (!groupedAppointments.containsKey(dateOnly)) {
                groupedAppointments[dateOnly] = [];
              }
              groupedAppointments[dateOnly]!.add(booking);
            }
          }

          // Sort dates
          final List<DateTime> sortedDates =
              groupedAppointments.keys.toList()..sort((a, b) => a.compareTo(b));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedDates.length,
            itemBuilder: (context, dateIndex) {
              final DateTime date = sortedDates[dateIndex];
              final List<Booking> bookingsForDate = groupedAppointments[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  ...bookingsForDate.map((booking) {
                    return _buildAppointmentCard(booking);
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Booking booking) {
    final String jobType = booking.selectedCategory;
    final String clientName = booking.clientName;
    final String scheduledTime = booking.scheduledTime ?? 'Not specified';
    final String duration = booking.duration ?? 'Not specified';
    final String notes = booking.notes ?? 'No additional notes.';
    final GeoPoint? location = booking.location;

    Future<String> getDisplayAddress() async {
      if (location == null) return 'Location not specified';
      return await getAddressFromLatLng(location.latitude, location.longitude);
    }

    return Card(
      elevation: 4,
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
            const Divider(height: 16),
            _buildInfoRow(Icons.person, 'Client:', clientName),
            _buildInfoRow(Icons.access_time, 'Time:', scheduledTime),
            _buildInfoRow(Icons.hourglass_empty, 'Duration:', duration),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Location: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: FutureBuilder<String>(
                    future: getDisplayAddress(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          'Loading location...',
                          style: TextStyle(color: Colors.grey),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      } else {
                        return Text(
                          snapshot.data ?? 'Location not specified',
                          style: TextStyle(color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Notes: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(color: Colors.grey[700]),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to job details or start job flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View Job Details (Not Implemented Yet)'),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
