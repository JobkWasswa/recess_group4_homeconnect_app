import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Only if you're passing Timestamp

class ServiceProviderSingleBookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const ServiceProviderSingleBookingDetailScreen({
    super.key,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? scheduledDate;
    final rawDate = bookingData['scheduledDate'];

    if (rawDate is Timestamp) {
      scheduledDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      scheduledDate = rawDate;
    } else if (rawDate is String) {
      try {
        scheduledDate = DateTime.parse(rawDate);
      } catch (_) {
        scheduledDate = null;
      }
    }

    final service = bookingData['serviceCategory'] ?? 'Unknown Service';
    final rawDuration = bookingData['duration'];
    final duration =
        (rawDuration != null && rawDuration.toString().trim().isNotEmpty)
            ? rawDuration.toString()
            : 'Unknown Duration';

    print('✅ Duration is: $duration');
    final notes = bookingData['notes'] ?? '';
    final clientName = bookingData['clientName'] ?? 'Unknown Client';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDetailRow(Icons.person, 'Client', clientName),
                if (scheduledDate != null) ...[
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat('dd MMM yyyy').format(scheduledDate),
                  ),
                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    DateFormat('hh:mm a').format(scheduledDate),
                  ),
                ],
                _buildDetailRow(Icons.timer, 'Duration', duration),
                if (notes.isNotEmpty)
                  _buildDetailRow(Icons.note, 'Notes', notes),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
