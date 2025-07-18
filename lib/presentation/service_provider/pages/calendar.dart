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
      _unavailableDates = data.keys.map((key) => key.toString()).toSet();
    });
  }

  Future<void> _toggleDate(DateTime day) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);

    final docRef = FirebaseFirestore.instance
        .collection('service_providers')
        .doc(widget.providerId);

    setState(() {
      if (_unavailableDates.contains(dateKey)) {
        _unavailableDates.remove(dateKey);
        docRef.update({'unavailable_days.$dateKey': FieldValue.delete()});
      } else {
        _unavailableDates.add(dateKey);
        docRef.set({
          'unavailable_days.$dateKey': true,
        }, SetOptions(merge: true));
      }
    });
  }

  bool _isUnavailable(DateTime day) {
    String formatted = DateFormat('yyyy-MM-dd').format(day);
    return _unavailableDates.contains(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Availability")),
      body: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(days: 90)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (_) => false,
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
    );
  }
}
