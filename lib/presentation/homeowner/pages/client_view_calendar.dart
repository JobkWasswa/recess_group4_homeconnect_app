import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ClientViewCalendar extends StatefulWidget {
  final String providerId;
  const ClientViewCalendar({required this.providerId});

  @override
  _ClientViewCalendarState createState() => _ClientViewCalendarState();
}

class _ClientViewCalendarState extends State<ClientViewCalendar> {
  Set<String> _unavailableDates = {};
  DateTime _focusedDay = DateTime.now();

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
      _unavailableDates = data.keys.map((k) => k.toString()).toSet();
    });
  }

  bool _isUnavailable(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    return _unavailableDates.contains(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: _focusedDay,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          bool isUnavailable = _isUnavailable(date);
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isUnavailable ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
            child: Text('${date.day}', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}
