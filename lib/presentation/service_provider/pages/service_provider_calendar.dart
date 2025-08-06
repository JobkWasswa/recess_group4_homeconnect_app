import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/presentation/homeowner/pages/create_booking_screen.dart';
import 'package:homeconnect/data/models/booking_time_range.dart';

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
  Map<DateTime, int> bookingCounts = {};

  @override
  void initState() {
    super.initState();
    fetchBookingDates();
  }

  Future<List<BookingTimeRange>> fetchBookingsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceProviderId', isEqualTo: widget.provider.id)
            .where('status', whereIn: ['pending', 'confirmed'])
            .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
            .where('scheduledDate', isLessThan: endOfDay)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BookingTimeRange(
        start: (data['scheduledDate'] as Timestamp).toDate(),
        end: (data['endDateTime'] as Timestamp).toDate(),
      );
    }).toList(); // returns an empty list if no bookings
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

        final bool isFullDay = doc['isFullDay'] ?? false;

        if (isFullDay) {
          // Full day booking blocks the whole day
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
        bookingCounts = dateBookingCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isBooked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return bookedDates.contains(normalized);
  }

  bool isPartiallyBooked(DateTime day) {
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

    final bookedTimeRanges = await fetchBookingsForDay(normalizedDay);

    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateBookingScreen(
              serviceProvider: widget.provider,
              serviceCategory: widget.category,
              initialDate: normalizedDay,
              bookedTimeRanges: bookedTimeRanges,
            ),
      ),
    );

    if (result != null) {
      // ✅ Send booking result back to the provider list screen
      Navigator.pop(context, result);
    } else {
      // If user cancelled, just refresh bookings
      await fetchBookingDates();
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
