import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';

class CreateBookingScreen extends StatefulWidget {
  final ServiceProviderModel serviceProvider;
  final String serviceCategory;
  final DateTime initialDate;
  final bool isReschedule; // Optional: For rescheduling flows

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
  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFullDay = false;
  bool _isLoading = false;
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

  // Combined date/time pickers from both screens
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
          // Auto-validate time range
          if (_startTime != null && _isEndTimeBeforeStart()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End time must be after start time')),
            );
          }
        }
      });
    }
  }

  bool _isEndTimeBeforeStart() {
    return _endTime!.hour < _startTime!.hour || 
          (_endTime!.hour == _startTime!.hour && _endTime!.minute <= _startTime!.minute);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    // Time validation for partial-day bookings
    if (!_isFullDay && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    if (!_isFullDay && _isEndTimeBeforeStart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bookingData = {
        'userId': user.uid,
        'serviceProviderId': widget.serviceProvider.id,
        'serviceCategory': widget.serviceCategory,
        'date': Timestamp.fromDate(_selectedDate),
        'isFullDay': _isFullDay,
        'notes': _notesController.text.trim(),
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
        if (!_isFullDay) ...{
          'startTime': _startTime!.format(context),
          'endTime': _endTime!.format(context),
          'startTimeMinutes': _startTime!.hour * 60 + _startTime!.minute,
          'endTimeMinutes': _endTime!.hour * 60 + _endTime!.minute,
        },
        'providerName': widget.serviceProvider.name,
        'providerPhoto': widget.serviceProvider.profilePhoto,
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isReschedule 
              ? 'Booking rescheduled successfully' 
              : 'Booking created successfully')),
        );
      }
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              // Service Provider Header (from first screen)
              _buildProviderHeader(),
              const Divider(height: 30),
              
              // Date Picker
              _buildDatePicker(),
              const SizedBox(height: 20),
              
              // Full Day Toggle (from second screen)
              _buildFullDayToggle(),
              const SizedBox(height: 20),
              
              // Time Pickers (conditionally shown)
              if (!_isFullDay) ...[
                _buildTimePicker(label: 'Start Time', time: _startTime, isStart: true),
                const SizedBox(height: 15),
                _buildTimePicker(label: 'End Time', time: _endTime, isStart: false),
                const SizedBox(height: 20),
              ],
              
              // Notes Field (from first screen)
              _buildNotesField(),
              const SizedBox(height: 30),
              
              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Widget Components
  Widget _buildProviderHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service: ${widget.serviceCategory}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: widget.serviceProvider.profilePhoto != null
                  ? NetworkImage(widget.serviceProvider.profilePhoto!)
                  : null,
              child: widget.serviceProvider.profilePhoto == null
                  ? const Icon(Icons.person, size: 25)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Provider: ${widget.serviceProvider.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: DateFormat('dd-MM-yyyy').format(_selectedDate),
          ),
          decoration: InputDecoration(
            labelText: 'Date *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.purple),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) => _selectedDate.isBefore(DateTime.now())
              ? 'Cannot select past dates'
              : null,
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildFullDayToggle() {
    return Row(
      children: [
        Checkbox(
          value: _isFullDay,
          onChanged: (val) => setState(() {
            _isFullDay = val!;
            if (_isFullDay) {
              _startTime = null;
              _endTime = null;
            }
          }),
        ),
        const Text('Full Day Booking', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTimePicker({required String label, required TimeOfDay? time, required bool isStart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectTime(context, isStart),
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(
                text: time?.format(context) ?? '--:--',
              ),
              decoration: InputDecoration(
                hintText: 'Select $label',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: const Icon(Icons.access_time, color: Colors.purple),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) => !_isFullDay && time == null
                  ? 'Please select $label'
                  : null,
              readOnly: true,
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Notes (optional):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Special instructions...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isReschedule ? 'Reschedule Booking' : 'Confirm Booking',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
