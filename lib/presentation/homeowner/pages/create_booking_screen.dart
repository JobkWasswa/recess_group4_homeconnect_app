import 'package:flutter/material.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:intl/intl.dart'; // For date formatting

class CreateBookingScreen extends StatefulWidget {
  final ServiceProviderModel serviceProvider;
  final String serviceCategory;
  final DateTime? initialDate; // ✅ New parameter

  const CreateBookingScreen({
    super.key,
    required this.serviceProvider,
    required this.serviceCategory,
    this.initialDate, // ✅ Include in constructor
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate; // ✅ Prefill date from calendar
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _confirmBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null ||
          _selectedTime == null ||
          _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date, time, and end time.'),
          ),
        );
        return;
      }

      // scheduledDate: Date only (time ignored, set to midnight)
      final scheduledDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      // scheduledTimeDisplay: string version of start time (for UI and storing in Booking)
      final scheduledTimeDisplay = _selectedTime!.format(context);

      // endDateTime: full DateTime including selected date + end time
      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );

      // Return booking details map
      Navigator.pop(context, {
        'scheduledDate': scheduledDate, // date only
        'scheduledTime': scheduledTimeDisplay, // formatted string start time
        'endDateTime': endDateTime, // full datetime for end
        'notes': _notesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Your Booking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                                    (context, error, stack) =>
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

              // Date Picker
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
                    readOnly: true,
                    validator: (value) {
                      if (_selectedDate == null) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Picker
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text:
                          _selectedTime == null
                              ? ''
                              : _selectedTime!.format(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Time *',
                      hintText: 'Select time',
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
                    readOnly: true,
                    validator: (value) {
                      if (_selectedTime == null) {
                        return 'Please select a time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // End Time Picker
              GestureDetector(
                onTap: () => _selectEndTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text:
                          _selectedEndTime == null
                              ? ''
                              : _selectedEndTime!.format(context),
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
                    readOnly: true,
                    validator: (value) {
                      if (_selectedEndTime == null) {
                        return 'Please select an end time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
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
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),

              // Confirm Button
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
