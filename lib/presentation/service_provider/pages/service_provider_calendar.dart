import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';

class ServiceProviderCalendarScreen extends StatefulWidget {
  final ServiceProviderModel provider;

  const ServiceProviderCalendarScreen({Key? key, required this.provider}) : super(key: key);

  @override
  State<ServiceProviderCalendarScreen> createState() => _ServiceProviderCalendarScreenState();
}

class _ServiceProviderCalendarScreenState extends State<ServiceProviderCalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    fetchBookings();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> fetchBookings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: widget.provider.id)
        .get();

    Map<DateTime, List<dynamic>> events = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp ts = data['bookingDate'];
      final DateTime bookingDate = DateTime.utc(ts.toDate().year, ts.toDate().month, ts.toDate().day);
      events.putIfAbsent(bookingDate, () => []).add(data);
    }

    setState(() {
      _events = events;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  Color _getColorForDate(DateTime day) {
    final events = _getEventsForDay(day);
    if (events.isEmpty) return Colors.green;
    if (events.length > 3) return Colors.red;
    return Colors.orange;
  }

  Widget _buildLegendBox(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay!, day),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents.value = _getEventsForDay(selectedDay);
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: _getColorForDate(day),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendBox(Colors.red, "Fully Booked"),
                _buildLegendBox(Colors.orange, "Partially Booked"),
                _buildLegendBox(Colors.green, "Available"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(child: Text("No bookings for this day."));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return ListTile(
                      title: Text("Booking: ${event['clientName'] ?? 'N/A'}"),
                      subtitle: Text("Time: ${event['bookingTime'] ?? 'N/A'}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
