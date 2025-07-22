import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';

class ServiceProviderViewCalendarScreen extends StatefulWidget {
  final ServiceProviderModel provider;

  const ServiceProviderViewCalendarScreen({super.key, required this.provider});

  @override
  State<ServiceProviderViewCalendarScreen> createState() =>
      _ServiceProviderViewCalendarScreenState();
}

class _ServiceProviderViewCalendarScreenState
    extends State<ServiceProviderViewCalendarScreen> {
  Set<DateTime> bookedDates = {};
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Debug print to check the provider ID received
    print(
      'ServiceProviderViewCalendarScreen: Received provider ID: ${widget.provider.id}',
    );
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    // Ensure that widget.provider.id is not null or empty before using it in the query
    // The 'id' field is required in your ServiceProviderModel, so it should not be null.
    // However, an empty string check is still good practice.
    if (widget.provider.id.isEmpty) {
      print(
        'Error: Provider ID is empty in ServiceProviderViewCalendarScreen. Cannot fetch bookings.',
      );
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot load calendar: Provider ID is missing.'),
          ),
        );
      }
      return; // Exit if ID is invalid
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where(
                'serviceProviderId',
                isEqualTo: widget.provider.id,
              ) // <--- FIXED: Changed to .id
              .where('status', isEqualTo: 'confirmed')
              .get();

      final dates =
          snapshot.docs
              .map((doc) => (doc['scheduledDate'] as Timestamp).toDate())
              .map((date) => DateTime(date.year, date.month, date.day))
              .toSet();

      setState(() {
        bookedDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load calendar data: $e')),
        );
      }
    }
  }

  bool _isBooked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return bookedDates.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Booking Calendar')),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(),
              ),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 30)),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  weekendDecoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red[400],
                    shape: BoxShape.circle,
                  ),
                  markerSize: 8.0,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    final isBooked = bookedDates.contains(normalized);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBooked ? Colors.red[400] : Colors.green[300],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
