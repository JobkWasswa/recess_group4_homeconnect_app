import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderCalendarEditPage extends StatefulWidget {
  final String providerId;
  const ProviderCalendarEditPage({required this.providerId});

  @override
  State<ProviderCalendarEditPage> createState() =>
      _ProviderCalendarEditPageState();
}

class _ProviderCalendarEditPageState extends State<ProviderCalendarEditPage> {
  DateTime _focusedDay = DateTime.now();
  Set<String> _unavailableDates = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUnavailableDates();
  }

  Future<void> _loadUnavailableDates() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(widget.providerId)
            .get();

    final Map data = doc.data()?['unavailable_days'] ?? {};
    setState(() {
      _unavailableDates =
          data.keys.map((key) => key.toString()).toSet(); // Cast safely
    });
  }

  void _toggleDate(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    setState(() {
      if (_unavailableDates.contains(dateKey)) {
        _unavailableDates.remove(dateKey);
      } else {
        _unavailableDates.add(dateKey);
      }
    });
  }

  bool _isUnavailable(DateTime day) {
    String formatted = DateFormat('yyyy-MM-dd').format(day);
    return _unavailableDates.contains(formatted);
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);

    final docRef = FirebaseFirestore.instance
        .collection('service_providers')
        .doc(widget.providerId);

    Map<String, dynamic> newUnavailableMap = {
      for (var date in _unavailableDates) date: true,
    };

    await docRef.set({
      'unavailable_days': newUnavailableMap,
    }, SetOptions(merge: true));

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Availability saved!')));
  }

  void _resetAvailability() {
    setState(() {
      _unavailableDates.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All days reset to available.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Availability")),
      body: Column(
        children: [
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  bool isUnavailable = _isUnavailable(date);
                  return GestureDetector(
                    onTap: () => _toggleDate(date),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isUnavailable ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _saveAvailability,
                    icon: Icon(Icons.save),
                    label: Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _resetAvailability,
                    icon: Icon(Icons.refresh),
                    label: Text("Reset to All Available"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
