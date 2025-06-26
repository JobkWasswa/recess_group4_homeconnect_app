import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarAvailabilityScreen extends StatefulWidget {
  const CalendarAvailabilityScreen({super.key});

  @override
  State<CalendarAvailabilityScreen> createState() =>
      _CalendarAvailabilityScreenState();
}

class _CalendarAvailabilityScreenState
    extends State<CalendarAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Map<String, String>> _availability = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  void _saveSelectedDateAvailability() {
    if (_selectedDay != null && _startTime != null && _endTime != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      _availability[dateKey] = {
        'start': _formatTime(_startTime),
        'end': _formatTime(_endTime),
      };
      setState(() {
        _startTime = null;
        _endTime = null;
      });
    }
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'provider123';
    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .update({'availability': _availability});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Availability saved to Firestore')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Availability')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    'Set availability for ${DateFormat('EEEE, MMM d').format(_selectedDay!)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => _pickTime(true),
                        child: Text('Start: ${_formatTime(_startTime)}'),
                      ),
                      TextButton(
                        onPressed: () => _pickTime(false),
                        child: Text('End: ${_formatTime(_endTime)}'),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveSelectedDateAvailability,
                    icon: const Icon(Icons.check),
                    label: const Text('Add Availability'),
                  ),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView(
              children:
                  _availability.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        '${entry.value['start']} - ${entry.value['end']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _availability.remove(entry.key);
                          });
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _saveToFirestore,
          icon: const Icon(Icons.save),
          label: const Text('Save All'),
        ),
      ),
    );
  }
}
