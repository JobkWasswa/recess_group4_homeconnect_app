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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true; // 👈 loading state

  @override
  void initState() {
    super.initState();
    fetchAcceptedBookingDates();
  }

  Future<void> fetchAcceptedBookingDates() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: widget.provider.id)
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
      print('Error fetching booking dates: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isBooked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return bookedDates.contains(normalized);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (_isBooked(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This date is already booked')),
      );
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final bookingDetails = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateBookingScreen(
              serviceProvider: widget.provider,
              serviceCategory: widget.category,
              initialDate: DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              ),
            ),
      ),
    );

    if (bookingDetails != null) {
      Navigator.pop(context, bookingDetails);
    }
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
                child:
                    LinearProgressIndicator(), // or CircularProgressIndicator
              ),
            Expanded(
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
                    color: Colors.blue[300],
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[200],
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[200],
                  ),
                  outsideDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    final isBooked = bookedDates.contains(normalized);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBooked ? Colors.red[300] : Colors.green[300],
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
