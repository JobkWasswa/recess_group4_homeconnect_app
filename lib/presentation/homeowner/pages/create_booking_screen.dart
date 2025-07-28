import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:homeconnect/data/models/booking_time_range.dart';

class CreateBookingScreen extends StatefulWidget {
  final ServiceProviderModel serviceProvider;
  final String serviceCategory;
  final DateTime initialDate;
  final bool isReschedule;
  final List<BookingTimeRange> bookedTimeRanges;

  const CreateBookingScreen({
    super.key,
    required this.serviceProvider,
    required this.serviceCategory,
    required this.initialDate,
    this.isReschedule = false,
    required this.bookedTimeRanges,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFullDay = false;
  late List<BookingTimeRange> _bookedTimeRanges;
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _bookedTimeRanges = widget.bookedTimeRanges;
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Checks if the end time is before the start time
  bool _isEndTimeBeforeStart() {
    if (_startTime == null || _endTime == null) return false;
    final a = DateTime(0, 0, 0, _startTime!.hour, _startTime!.minute);
    final b = DateTime(0, 0, 0, _endTime!.hour, _endTime!.minute);
    return b.isBefore(a);
  }

  // Showing the time picker dialog
  Future<void> _selectTime(BuildContext ctx, bool isStart) async {
    if (_isFullDay) return; // Disable time selection if it's a full-day booking
    final picked = await showTimePicker(
      context: ctx,
      initialTime:
          isStart
              ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
              : (_endTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
          // Show a snackbar if end time is before start time
          if (_startTime != null && _isEndTimeBeforeStart()) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time'),
              ),
            );
          }
        }
      });
    }
  }

  // Handles the booking confirmation logic
  void _confirmBooking() {
    // Validate all form fields first
    if (!_formKey.currentState!.validate()) {
      return; // Stop if any validation fails
    }

    // Check if times are selected for non-full-day bookings
    if (!_isFullDay && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end times.'),
        ),
      );
      return;
    }

    final scheduledDate = _selectedDate!;
    final startDateTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      _isFullDay ? 0 : _startTime!.hour,
      _isFullDay ? 0 : _startTime!.minute,
    );
    final endDateTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      _isFullDay ? 23 : _endTime!.hour,
      _isFullDay ? 59 : _endTime!.minute,
    );

    // Check for time conflicts with existing bookings
    bool hasConflict = _bookedTimeRanges.any(
      (r) => startDateTime.isBefore(r.end) && endDateTime.isAfter(r.start),
    );

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time overlaps with existing bookings.'),
        ),
      );
      return;
    }

    // If all checks pass, pop the screen with booking details
    Navigator.pop(context, {
      'scheduledDate': scheduledDate,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'isFullDay': _isFullDay,
      'notes': _notesController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReschedule ? 'Reschedule Booking' : 'New Booking',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, // Assign the GlobalKey to the Form
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
              const SizedBox(height: 12),

              // Date picker TextFormField
              TextFormField(
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate!,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  hintText: 'Tap to select',
                  suffixIcon: Icon(Icons.calendar_today),
                  filled: true,
                ),
                controller: TextEditingController(
                  text: dateFmt.format(_selectedDate!),
                ),
                // Validator to ensure a date is selected
                validator:
                    (value) =>
                        _selectedDate == null ? 'Please select a date' : null,
              ),
              const SizedBox(height: 12),

              // Full day switch
              SwitchListTile(
                title: const Text('Full Day Booking'),
                activeColor: Colors.purple,
                value: _isFullDay,
                onChanged:
                    (v) => setState(() {
                      _isFullDay = v;
                      if (v) {
                        _startTime =
                            null; // Clear times if full day is selected
                        _endTime = null;
                      }
                    }),
              ),
              const SizedBox(height: 8),

              // Conflicts display for booked slots
              if (_bookedTimeRanges.isNotEmpty) ...[
                const Text(
                  'Booked slots:',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ..._bookedTimeRanges.map(
                  (r) => Text(
                    '${DateFormat('hh:mm a').format(r.start)} – ${DateFormat('hh:mm a').format(r.end)}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Time pickers for start and end times
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => _selectTime(
                            context,
                            true,
                          ), // Tap to select start time
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Start Time *',
                            suffixIcon: Icon(Icons.access_time),
                            filled: true,
                          ),
                          controller: TextEditingController(
                            text: _startTime?.format(context) ?? '',
                          ),
                          // Validator for start time
                          validator:
                              (value) =>
                                  !_isFullDay && _startTime == null
                                      ? 'Please select a start time'
                                      : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => _selectTime(
                            context,
                            false,
                          ), // Tap to select end time
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'End Time *',
                            suffixIcon: Icon(Icons.access_time),
                            filled: true,
                          ),
                          controller: TextEditingController(
                            text: _endTime?.format(context) ?? '',
                          ),
                          // Validator for end time
                          validator:
                              (value) =>
                                  !_isFullDay && _endTime == null
                                      ? 'Please select an end time'
                                      : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Notes TextField
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 3,
              ),

              const Spacer(),

              // Confirm button with gradient - now tappable!
              Center(
                child: GestureDetector(
                  // Added GestureDetector
                  onTap: _confirmBooking, // This is what makes the button work!
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8A80), Color(0xFF6A11CB)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      child: Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
