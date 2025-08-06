import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ServiceProviderCalendarViewScreen extends StatefulWidget {
  const ServiceProviderCalendarViewScreen({super.key});

  @override
  State<ServiceProviderCalendarViewScreen> createState() =>
      _ServiceProviderCalendarViewScreenState();
}

class _ServiceProviderCalendarViewScreenState
    extends State<ServiceProviderCalendarViewScreen> {
  Set<DateTime> bookedDates = {};
  Set<DateTime> partiallyBookedDates = {};
  DateTime _focusedDay = DateTime.now();
  final int maxDailyBookings = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookingDates();
  }

  Future<void> fetchBookingDates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: userId)
              .get();

      final Map<DateTime, int> dateBookingCount = {};
      final Set<DateTime> confirmed = {};
      final Set<DateTime> partial = {};

      for (final doc in snapshot.docs) {
        final status = doc['status'] ?? 'pending';
        if (status == 'cancelled' || status == 'rejected_by_provider') continue;

        final Timestamp? startTimestamp = doc['scheduledDate'];
        if (startTimestamp == null) continue;

        final DateTime start = startTimestamp.toDate();
        final normalized = DateTime(start.year, start.month, start.day);
        final bool isFullDay = doc['isFullDay'] ?? false;

        if (isFullDay) {
          dateBookingCount[normalized] = maxDailyBookings;
        } else {
          dateBookingCount[normalized] =
              (dateBookingCount[normalized] ?? 0) + 1;
        }
      }

      dateBookingCount.forEach((date, count) {
        if (count >= maxDailyBookings) {
          confirmed.add(date);
        } else if (count > 0) {
          partial.add(date);
        }
      });

      setState(() {
        bookedDates = confirmed;
        partiallyBookedDates = partial;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showBookingDetailsDialog(DateTime date) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceProviderId', isEqualTo: userId)
            .where(
              'scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    final bookings =
        snapshot.docs
            .where(
              (doc) =>
                  doc['status'] != 'cancelled' &&
                  doc['status'] != 'rejected_by_provider',
            )
            .map((doc) {
              final start = (doc['scheduledDate'] as Timestamp).toDate();
              final end = (doc['endDateTime'] as Timestamp?)?.toDate();
              final clientName = doc['clientName'] ?? 'Unknown';
              final isFullDay = doc['isFullDay'] ?? false;

              final timeRange =
                  isFullDay
                      ? 'Full Day'
                      : end != null
                      ? '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}'
                      : '${DateFormat.jm().format(start)}';

              return '$clientName: $timeRange';
            })
            .toList();

    if (bookings.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Bookings on ${DateFormat.yMMMd().format(date)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: bookings.map((b) => Text(b)).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildLegendItem(Colors.green[300]!, 'Available'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange[300]!, 'Partially Booked'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red[300]!, 'Booked'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.blue[300]!, 'Today'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'My Booking Calendar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(),
              ),
            _buildLegend(),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  final normalized = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  );
                  if (bookedDates.contains(normalized) ||
                      partiallyBookedDates.contains(normalized)) {
                    _showBookingDetailsDialog(normalized);
                  }
                },
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[300],
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    Color bgColor = Colors.green[300]!;

                    if (bookedDates.contains(normalized)) {
                      bgColor = Colors.red[300]!;
                    } else if (partiallyBookedDates.contains(normalized)) {
                      bgColor = Colors.orange[300]!;
                    }

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
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
