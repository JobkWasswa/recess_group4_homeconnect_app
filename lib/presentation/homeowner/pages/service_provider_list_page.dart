// File: homeconnect/presentation/homeowner/pages/list_of_serviceproviders.dart
import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/list_of _serviceproviders.dart';
import 'package:geolocator/geolocator.dart'; // Needed for getting user location
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for GeoPoint
import 'package:intl/intl.dart'; // Import for date formatting in UI

class ServiceProviderListPage extends StatefulWidget {
  final String? searchQuery;
  final String? category;

  const ServiceProviderListPage({super.key, this.searchQuery, this.category});

  @override
  State<ServiceProviderListPage> createState() =>
      _ServiceProviderListPageState();
}

class _ServiceProviderListPageState extends State<ServiceProviderListPage> {
  GeoPoint? _userCurrentLocation;
  bool _isLoadingLocation = true;
  String? _locationError;
  DateTime?
  _selectedDateTime; // Add this state variable for the desired date/time

  @override
  void initState() {
    super.initState();
    _determinePosition().then((_) {
      // Initialize _selectedDateTime after location is determined
      if (_userCurrentLocation != null) {
        // Default to an hour from now, ensuring it's not in the past
        _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Location services are disabled. Please enable them.';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError =
              'Location permissions are denied. Cannot search by distance.';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Location permissions are permanently denied. Please enable from app settings.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userCurrentLocation = GeoPoint(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get current location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  // Function to show date and time picker
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // 1 year from now
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // The ValueKey on ServiceProvidersList will handle the rebuild
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final query = args != null ? args['query'] as String? : null;
    final category = args != null ? args['category'] as String? : null;

    final searchValue = query ?? category;

    if (searchValue == null || searchValue.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Missing search input (query or category).')),
      );
    }

    if (_isLoadingLocation) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Professionals')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                _locationError ??
                    'Getting your location to find nearby providers...',
              ),
            ],
          ),
        ),
      );
    }

    if (_locationError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Professionals')),
        body: Center(child: Text(_locationError!)),
      );
    }

    if (_userCurrentLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Professionals')),
        body: const Center(
          child: Text(
            'Could not determine your location. Cannot find nearby providers.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Providers for $searchValue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateTime(context),
            tooltip: 'Select Booking Date & Time',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _selectedDateTime == null
                  ? 'Please select a date and time to filter availability.'
                  : 'Searching for: $searchValue on ${DateFormat('dd/MM/yyyy h:mm a').format(_selectedDateTime!.toLocal())}', // Display selected time
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ServiceProvidersList(
              // Using ValueKey to force rebuild of ServiceProvidersList when _selectedDateTime changes
              key: ValueKey(_selectedDateTime),
              category: searchValue,
              userLocation: _userCurrentLocation!,
              desiredDateTime: _selectedDateTime, // Pass the desired date/time
            ),
          ),
        ],
      ),
    );
  }
}
