import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderSingleBookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const ServiceProviderSingleBookingDetailScreen({
    super.key,
    required this.bookingData,
  });

  DateTime? tryParseDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          try {
            return DateFormat("MMM dd, yyyy h:mm a").parse(value);
          } catch (_) {
            return null;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final scheduledDate = tryParseDate(bookingData['scheduledDate']);
    final endDateTime = tryParseDate(bookingData['endDateTime']);

    final selectedCategory = bookingData['selectedCategory']?.toString().trim();
    final clientName = bookingData['clientName'] ?? 'N/A';
    final notes = bookingData['notes'] ?? 'N/A';
    final isFullDay = bookingData['isFullDay'] ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            detailRow("Client Name", clientName),
            detailRow(
              "Category",
              (selectedCategory != null && selectedCategory.isNotEmpty)
                  ? selectedCategory
                  : 'N/A',
            ),
            detailRow(
              "Full Day?",
              isFullDay ? "Yes (Full Day Booking)" : "No (Time Range)",
            ),
            const SizedBox(height: 12),

            detailRow(
              "Booked Date",
              scheduledDate != null ? dateFormat.format(scheduledDate) : 'N/A',
            ),
            detailRow(
              "Start Time",
              scheduledDate != null ? timeFormat.format(scheduledDate) : 'N/A',
            ),
            detailRow(
              "End Time",
              endDateTime != null ? timeFormat.format(endDateTime) : 'N/A',
            ),
            const SizedBox(height: 12),

            detailRow("Notes", notes),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
