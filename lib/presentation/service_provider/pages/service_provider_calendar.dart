import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/presentation/homeowner/pages/create_booking_screen.dart';

class ServiceProviderCalendarScreen extends StatefulWidget {
  final ServiceProviderModel provider;
  final String category;

  const ServiceProviderCalendarScreen({
    super.key,
    required this.provider,
    required this.category,
  });

  @override
  State<ServiceProviderCalendarScreen> createState() =>
      _ServiceProviderCalendarScreenState();
}

class _ServiceProviderCalendarScreenState
    extends State<ServiceProviderCalendarScreen> {
  Set<DateTime> bookedDates = {};
  Set<DateTime> partiallyBookedDates = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  final int maxDailyBookings = 3;
  Map<DateTime, int> _bookingCounts = {};

  @override
  void initState() {
    super.initState();
    fetchBookingDates();
  }

  Future<void> fetchBookingDates() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: widget.provider.id)
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

        dateBookingCount[normalized] = (dateBookingCount[normalized] ?? 0) + 1;
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
        _bookingCounts = dateBookingCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isBooked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return bookedDates.contains(normalized);
  }

  bool _isPartiallyBooked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return partiallyBookedDates.contains(normalized);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    if (_isBooked(normalizedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This date is fully booked')),
      );
      return;
    }

    setState(() {
      _selectedDay = normalizedDay;
      _focusedDay = focusedDay;
    });

    final isFullyBooked =
        (_bookingCounts[normalizedDay] ?? 0) >= maxDailyBookings;

    if (isFullyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This date is fully booked')),
      );
      return;
    }

    final bookingDetails = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateBookingScreen(
              serviceProvider: widget.provider,
              serviceCategory: widget.category,
              initialDate: normalizedDay,
            ),
      ),
    );

    if (bookingDetails != null) {
      Navigator.pop(context, bookingDetails);
    }
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
            const SizedBox(width: 16),
            _buildLegendItem(Colors.purple, 'Selected'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Booking Date')),
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
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
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
