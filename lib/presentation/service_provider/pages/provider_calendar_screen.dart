import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:homeconnect/data/models/appointment_modal.dart';
import 'package:homeconnect/data/repositories/service_provider_repo.dart'; 

class ProviderCalendarScreen extends StatefulWidget {
  const ProviderCalendarScreen({super.key});

  @override
  State<ProviderCalendarScreen> createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends State<ProviderCalendarScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ServiceProviderRepository _serviceProviderRepository =
      ServiceProviderRepository(); // NEW: Instantiate repository

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events =
      {}; // Store events for the calendar (using Appointment model)

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Initialize selected day
  }

  // Helper to get events for a given day
  List<Appointment> _getEventsForDay(DateTime day) {
    // Normalize the day to remove time component for consistent lookup
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Appointments'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Please log in to view your appointments.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Appointment>>(
        // Changed to List<Appointment>
        stream: _serviceProviderRepository.getProviderAppointments(
          currentUser.uid,
        ), // Use new repository method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Process fetched data into events map for table_calendar
          _events = {}; // Clear previous events
          for (var appointment in snapshot.data!) {
            // Iterate through Appointment objects
            final normalizedDate = DateTime(
              appointment.scheduledDate.year,
              appointment.scheduledDate.month,
              appointment.scheduledDate.day,
            );
            if (_events[normalizedDate] == null) {
              _events[normalizedDate] = [];
            }
            _events[normalizedDate]!.add(appointment);
                    }

          // Sort appointments within each day by scheduled time
          _events.forEach((key, value) {
            value.sort((a, b) {
              // Attempt to parse time strings for sorting, default to start of day if parsing fails
              DateTime timeA = a.scheduledDate; // Start with scheduled date
              DateTime timeB = b.scheduledDate; // Start with scheduled date

              try {
                if (a.scheduledTime.isNotEmpty) {
                  // Check if scheduledTime is not empty
                  final timeParts = a.scheduledTime.split(RegExp(r'[:\s]'));
                  int hour = int.parse(timeParts[0]);
                  int minute = int.parse(timeParts[1]);
                  if (timeParts.length > 2 &&
                      timeParts[2].toLowerCase() == 'pm' &&
                      hour < 12) {
                    hour += 12;
                  } else if (timeParts.length > 2 &&
                      timeParts[2].toLowerCase() == 'am' &&
                      hour == 12) {
                    hour = 0;
                  }
                  timeA = DateTime(
                    timeA.year,
                    timeA.month,
                    timeA.day,
                    hour,
                    minute,
                  );
                }
              } catch (e) {
                debugPrint(
                  'Error parsing scheduledTime for sorting (A): ${a.scheduledTime} - $e',
                );
              }

              try {
                if (b.scheduledTime.isNotEmpty) {
                  // Check if scheduledTime is not empty
                  final timeParts = b.scheduledTime.split(RegExp(r'[:\s]'));
                  int hour = int.parse(timeParts[0]);
                  int minute = int.parse(timeParts[1]);
                  if (timeParts.length > 2 &&
                      timeParts[2].toLowerCase() == 'pm' &&
                      hour < 12) {
                    hour += 12;
                  } else if (timeParts.length > 2 &&
                      timeParts[2].toLowerCase() == 'am' &&
                      hour == 12) {
                    hour = 0;
                  }
                  timeB = DateTime(
                    timeB.year,
                    timeB.month,
                    timeB.day,
                    hour,
                    minute,
                  );
                }
              } catch (e) {
                debugPrint(
                  'Error parsing scheduledTime for sorting (B): ${b.scheduledTime} - $e',
                );
              }
              return timeA.compareTo(timeB);
            });
          });

          return Column(
            children: [
              TableCalendar<Appointment>(
                // Changed generic type to Appointment
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
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
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child:
                    _selectedDay == null ||
                            _getEventsForDay(_selectedDay!).isEmpty
                        ? Center(
                          child: Text(
                            _selectedDay == null
                                ? 'Select a date to view appointments.'
                                : 'No appointments for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final appointment =
                                _getEventsForDay(_selectedDay!)[index];
                            return _buildAppointmentCard(appointment);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    // Changed parameter to Appointment
    final String jobType = appointment.serviceCategory;
    final String clientName = appointment.clientName;
    final String scheduledTime =
        appointment.scheduledTime; // No longer nullable
    final String duration = appointment.duration; // No longer nullable
    final String notes = appointment.notes ?? 'No additional notes.';
    // Location is explicitly excluded from this screen's display

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
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
            _buildInfoRow(Icons.access_time, 'Time:', scheduledTime),
            _buildInfoRow(Icons.hourglass_empty, 'Duration:', duration),
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
                  // TODO: Implement navigation to job details or start job flow
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
}
