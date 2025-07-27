import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homeconnect/data/models/booking.dart'; // Ensure Booking model is imported

class ServiceProviderCalendarViewScreen extends StatefulWidget {
  const ServiceProviderCalendarViewScreen({super.key});

  @override
  State<ServiceProviderCalendarViewScreen> createState() => _ServiceProviderCalendarViewScreen();
}

class _ServiceProviderCalendarViewScreen extends State<ServiceProviderCalendarViewScreen> {
  Set<DateTime> bookedDates = {};
  Set<DateTime> partiallyBookedDates = {};
  DateTime _focusedDay = DateTime.now();
  final int maxDailyBookings = 3; // Define your maximum daily bookings
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookingDates();
  }

  Future<void> fetchBookingDates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

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
        // Only consider active bookings for calendar display
        if (status == 'cancelled' ||
            status == 'rejected_by_provider' ||
            status == 'completed_by_provider')
          continue;

        final Timestamp? scheduledDateTimestamp = doc['scheduledDate'];
        if (scheduledDateTimestamp == null) continue;

        final DateTime scheduledDate = scheduledDateTimestamp.toDate();
        final normalized = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
        );
        final bool isFullDay = doc['isFullDay'] ?? false;

        if (isFullDay) {
          dateBookingCount[normalized] =
              maxDailyBookings; // Mark as fully booked
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
      print('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  // Function to show booking details in a modal bottom sheet
  void _showBookingDetailsBottomSheet(DateTime date) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
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

      final List<Booking> bookings =
          snapshot.docs
              .where(
                (doc) =>
                    doc['status'] != 'cancelled' &&
                    doc['status'] != 'rejected_by_provider' &&
                    doc['status'] !=
                        'completed_by_provider', // Only show active bookings
              )
              .map(
                (doc) => Booking.fromFirestore(doc),
              ) // CORRECTED: Use fromFirestore
              .toList();

      if (bookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No active bookings for ${DateFormat.yMMMd().format(date)}.',
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
        return;
      }

      // Sort bookings by time
      bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allows the sheet to take full height
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5, // Start at half screen height
            minChildSize: 0.25,
            maxChildSize: 0.9, // Maximize to almost full screen
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Bookings on ${DateFormat.yMMMd().format(date)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(bookings[index]);
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
    } catch (e) {
      print('Error fetching booking details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load booking details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget to build an individual appointment card
  Widget _buildAppointmentCard(Booking booking) {
    final String jobType = booking.selectedCategory;
    final String clientName = booking.clientName;
    final DateTime scheduledDate =
        booking.bookingDate; // Assuming bookingDate holds the full timestamp
    final String notes = booking.notes ?? 'No additional notes.';

    // Format time from bookingDate
    final String formattedTime = DateFormat.jm().format(
      scheduledDate.toLocal(),
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Color(0xFF6B7280),
              ),
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.person, 'Client:', clientName),
            _buildInfoRow(Icons.access_time, 'Time:', formattedTime),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Notes: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(color: Colors.grey[700]),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation to a detailed job view screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View Job Details (Not Implemented Yet)'),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
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
        title: const Text('My Booking Calendar'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
                lastDay: DateTime.now().add(
                  const Duration(days: 365 * 2),
                ), // Allow 2 years into the future
                focusedDay: _focusedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  final normalized = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  );
                  // Only show details if the date is booked or partially booked
                  if (bookedDates.contains(normalized) ||
                      partiallyBookedDates.contains(normalized)) {
                    _showBookingDetailsBottomSheet(normalized);
                  } else {
                    // Optionally, show a snackbar if there are no bookings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No bookings for ${DateFormat.yMMMd().format(normalized)}.',
                        ),
                        backgroundColor: Colors.grey[600],
                      ),
                    );
                  }
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[300],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.purple, // Highlight selected day
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.amber, // Default marker color for events
                    shape: BoxShape.circle,
                  ),
                  // Custom decorations for booked/partially booked dates
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[300], // Default available color
                  ),
                  holidayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[300],
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green[300],
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.purple,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.purple,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    Color bgColor =
                        Colors.green[300]!; // Default available color

                    if (bookedDates.contains(normalized)) {
                      bgColor = Colors.red[300]!; // Fully booked
                    } else if (partiallyBookedDates.contains(normalized)) {
                      bgColor = Colors.orange[300]!; // Partially booked
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
                  todayBuilder: (context, day, focusedDay) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    Color bgColor = Colors.blue[300]!; // Today's color

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
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ), // Highlight today
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
