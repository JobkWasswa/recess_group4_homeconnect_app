import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final Map<String, bool> _availability = {};
  final Map<String, TimeOfDay?> _startTimes = {};
  final Map<String, TimeOfDay?> _endTimes = {};

  @override
  void initState() {
    super.initState();
    for (var day in daysOfWeek) {
      _availability[day] = false;
      _startTimes[day] = null;
      _endTimes[day] = null;
    }
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTimes[day] = picked;
        } else {
          _endTimes[day] = picked;
        }
      });
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _saveAvailability() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'provider123';
    final availabilityMap = {
      for (var day in daysOfWeek)
        day: {
          'available': _availability[day],
          'start': formatTime(_startTimes[day]),
          'end': formatTime(_endTimes[day]),
        },
    };

    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .update({'availability': availabilityMap});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Availability saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Availability',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children:
            daysOfWeek.map((day) {
              final isAvailable = _availability[day] ?? false;
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ), // Adjusted margin
                elevation: 2, // Subtle shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ), // Rounded corners
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ), // Slightly bolder text
                      value: isAvailable,
                      activeColor: const Color(
                        0xFF6B4EEF,
                      ), // Purple switch color
                      onChanged: (val) {
                        setState(() {
                          _availability[day] = val;
                        });
                      },
                    ),
                    if (isAvailable)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          16,
                        ), // Adjusted padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _pickTime(day, true),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(
                                  0xFF6B4EEF,
                                ), // Purple text for buttons
                              ),
                              child: Text(
                                'Start: ${formatTime(_startTimes[day])}',
                              ),
                            ),
                            TextButton(
                              onPressed: () => _pickTime(day, false),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(
                                  0xFF6B4EEF,
                                ), // Purple text for buttons
                              ),
                              child: Text('End: ${formatTime(_endTimes[day])}'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: ElevatedButton(
          onPressed: _saveAvailability,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4EEF), // Purple button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
          ),
          child: const Text(
            'Save Availability',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
