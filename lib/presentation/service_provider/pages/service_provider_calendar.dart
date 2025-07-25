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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  final Map<DateTime, int> _bookingCounts = {};
  final int maxDailyBookings = 4;

  @override
  void initState() {
    super.initState();
    fetchBookingCounts();
  }

  Future<void> fetchBookingCounts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: widget.provider.id)
        .where('status', isEqualTo: 'accepted') // ✅ Only count accepted ones
        .get();


      final counts = <DateTime, int>{};

      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey('scheduledDate')) continue;
        final date = (doc['scheduledDate'] as Timestamp).toDate();
        final normalized = DateTime(date.year, date.month, date.day);
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }

      setState(() {
        _bookingCounts.clear();
        _bookingCounts.addAll(counts);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final normalizedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final isFullyBooked =
        (_bookingCounts[normalizedDay] ?? 0) >= maxDailyBookings;

    if (isFullyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This date is fully booked')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingScreen(
          serviceProvider: widget.provider,
          serviceCategory: widget.category,
          initialDate: normalizedDay,
        ),
      ),
    );

    if (result != null) {
      fetchBookingCounts(); // refresh after booking
    }
  }

  Color _getDayColor(DateTime day) {
    final count = _bookingCounts[DateTime(day.year, day.month, day.day)] ?? 0;
    final isSunday = day.weekday == DateTime.sunday;

    if (isSunday) return Colors.blue[200]!; // 🟦 Non-working
    if (count >= maxDailyBookings) return Colors.red[300]!; // 🔴 Fully booked
    if (count > 0) return Colors.orange[300]!; // 🟧 Partially booked
    return Colors.green[300]!; // 🟩 Available
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(Colors.green[300]!, 'Available'),
          _buildLegendItem(Colors.orange[300]!, 'Partially Booked'),
          _buildLegendItem(Colors.red[300]!, 'Fully Booked'),
          _buildLegendItem(Colors.blue[200]!, 'Non-working Day'),
          _buildLegendItem(Colors.purple, 'Selected'),
          _buildLegendItem(Colors.blue[400]!, 'Today'),
        ],
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
              child: SingleChildScrollView(
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 60)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  calendarStyle: CalendarStyle(
                    isTodayHighlighted: true,
                    selectedDecoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
                    weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
                    outsideDecoration: const BoxDecoration(shape: BoxShape.circle),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getDayColor(day),
                          shape: BoxShape.circle,
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
            ),
          ],
        ),
      ),
    );
  }
}
