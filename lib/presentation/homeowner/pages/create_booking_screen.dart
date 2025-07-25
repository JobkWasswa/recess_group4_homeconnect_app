import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';

class CreateBookingScreen extends StatefulWidget {
  final ServiceProviderModel serviceProvider;
  final String serviceCategory;
  final DateTime initialDate;
  final bool isReschedule;

  const CreateBookingScreen({
    super.key,
    required this.serviceProvider,
    required this.serviceCategory,
    required this.initialDate,
    this.isReschedule = false,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isEndTimeBeforeStart() {
    if (_startTime == null || _endTime == null) return false;
    final start = DateTime(0, 0, 0, _startTime!.hour, _startTime!.minute);
    final end = DateTime(0, 0, 0, _endTime!.hour, _endTime!.minute);
    return end.isBefore(start);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_startTime ?? TimeOfDay.now())
              : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
          if (_startTime != null && _isEndTimeBeforeStart()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time'),
              ),
            );
          }
        }
      });
    }
  }

  void _confirmBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date, start time, and end time'),
          ),
        );
        return;
      }

      final scheduledDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      Navigator.pop(context, {
        'scheduledDate': scheduledDate,
        'scheduledTime': _startTime!.format(context),
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'notes': _notesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReschedule ? 'Reschedule Booking' : 'New Booking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking for: ${widget.serviceCategory}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    child:
                        widget.serviceProvider.profilePhoto != null
                            ? ClipOval(
                              child: Image.network(
                                widget.serviceProvider.profilePhoto!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const Icon(Icons.person, size: 25),
                              ),
                            )
                            : const Icon(Icons.person, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Provider: ${widget.serviceProvider.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text(
                'Schedule Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text:
                          _selectedDate == null
                              ? ''
                              : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      hintText: 'Select date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.purple,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator:
                        (_) =>
                            _selectedDate == null
                                ? 'Please select a date'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectTime(context, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text:
                          _startTime == null ? '' : _startTime!.format(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Start Time *',
                      hintText: 'Select start time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: const Icon(
                        Icons.access_time,
                        color: Colors.purple,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator:
                        (_) =>
                            _startTime == null
                                ? 'Please select a start time'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectTime(context, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _endTime == null ? '' : _endTime!.format(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'End Time *',
                      hintText: 'Select end time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: const Icon(
                        Icons.access_time,
                        color: Colors.purple,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator:
                        (_) =>
                            _endTime == null
                                ? 'Please select an end time'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Additional Details (optional):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'e.g., specific instructions, preferred time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
