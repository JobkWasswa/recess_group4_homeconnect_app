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
      appBar: AppBar(title: const Text('Set Availability')),
      body: ListView(
        children:
            daysOfWeek.map((day) {
              final isAvailable = _availability[day] ?? false;
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(day),
                      value: isAvailable,
                      onChanged: (val) {
                        setState(() {
                          _availability[day] = val;
                        });
                      },
                    ),
                    if (isAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _pickTime(day, true),
                              child: Text(
                                'Start: ${formatTime(_startTimes[day])}',
                              ),
                            ),
                            TextButton(
                              onPressed: () => _pickTime(day, false),
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
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveAvailability,
          child: const Text('Save Availability'),
        ),
      ),
    );
  }
}
