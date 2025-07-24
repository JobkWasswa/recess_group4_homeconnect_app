import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:intl/intl.dart';

class ServiceProviderViewCalendarScreen extends StatefulWidget {
  final ServiceProviderModel provider;

  const ServiceProviderViewCalendarScreen({super.key, required this.provider});

  @override
  State<ServiceProviderViewCalendarScreen> createState() =>
      _ServiceProviderViewCalendarScreenState();
}

class _ServiceProviderViewCalendarScreenState
    extends State<ServiceProviderViewCalendarScreen> {
  Map<DateTime, List<DocumentSnapshot>> _bookingsByDate = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('ServiceProviderViewCalendarScreen: Received provider ID: ${widget.provider.id}');
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    if (widget.provider.id.isEmpty) {
      print('Error: Provider ID is empty.');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot load calendar: Provider ID is missing.')),
        );
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: widget.provider.id)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final Map<DateTime, List<DocumentSnapshot>> newBookings = {};
      for (var doc in snapshot.docs) {
        final Timestamp? scheduledDateTimestamp = doc['scheduledDate'] as Timestamp?;
        if (scheduledDateTimestamp != null) {
          final DateTime date = scheduledDateTimestamp.toDate();
          final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
          if (!newBookings.containsKey(normalizedDate)) {
            newBookings[normalizedDate] = [];
          }
          newBookings[normalizedDate]!.add(doc);
        }
      }

      setState(() {
        _bookingsByDate = newBookings;
        _isLoading = false;
        _selectedDay = DateTime.now();
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final normalized = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final bookings = _bookingsByDate[normalized] ?? [];

    if (bookings.isNotEmpty) {
      _showBookingDetailsBottomSheet(context, bookings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No confirmed bookings for ${DateFormat('MMM d, yyyy').format(selectedDay)}.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  void _showBookingDetailsBottomSheet(
    BuildContext context,
    List<DocumentSnapshot> bookings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Bookings on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final bookingData = bookings[index].data() as Map<String, dynamic>;
                        return _buildBookingDetailCard(bookingData);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingDetailCard(Map<String, dynamic> data) {
    final categories = data['categories'];
    final jobType = (categories is List && categories.isNotEmpty)
        ? categories[0].toString()
        : (categories?.toString() ?? 'Unknown');

    final Timestamp? scheduledDateTimestamp = data['scheduledDate'] as Timestamp?;
    final DateTime? scheduledDate = scheduledDateTimestamp?.toDate();
    final String? scheduledTime = data['scheduledTime'] as String?;
    final String? duration = data['duration'] as String?;
    final String? notes = data['notes'] as String?;
    final String clientName = data['clientName'] ?? 'Unknown Client';

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clientName,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (scheduledDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(scheduledDate)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (scheduledTime != null || duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${scheduledTime ?? 'N/A'}, Duration: ${duration ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: $notes',
                      style: TextStyle(color: Colors.grey[700]),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking Calendar'),
        backgroundColor: const Color(0xFF9333EA),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(color: Color(0xFF9333EA)),
              ),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5563),
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
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
                    final hasBookings = _bookingsByDate.containsKey(normalized);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasBookings ? Colors.red[400] : Colors.green[300],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                  markerBuilder: (context, day, events) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    if (_bookingsByDate.containsKey(normalized) &&
                        _bookingsByDate[normalized]!.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
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


