import 'package:flutter/material.dart';
import 'dart:math';
//import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider.dart';

class ServiceProviderListPage extends StatefulWidget {
  final String? searchQuery;
  final String? serviceCategory;
  final GeoPoint location;
  //final GeoPoint userLocation;

  const ServiceProviderListPage({
    super.key,
    this.searchQuery,
    this.serviceCategory,
    required this.location,
    // required this.userLocation,
  });

  @override
  State<ServiceProviderListPage> createState() =>
      _ServiceProviderListPageState();
}

class _ServiceProviderListPageState extends State<ServiceProviderListPage> {
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _error;
  List<ServiceProvider> _providers = [];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Query query = FirebaseFirestore.instance.collection('service_providers');

      // Apply search filter if query exists
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        query = query.where('skills', arrayContains: widget.searchQuery);
      }

      // Apply category filter if category exists
      if (widget.serviceCategory != null &&
          widget.serviceCategory!.isNotEmpty) {
        query = query.where(
          'categories',
          arrayContains: widget.serviceCategory,
        );
      }

      // Filter by distance if location is available
      query = query
          .where('location', isGreaterThan: _getMinGeoPoint())
          .where('location', isLessThan: _getMaxGeoPoint());

      final snapshot = await query.get();

      setState(() {
        _providers =
            snapshot.docs
                .map((doc) => ServiceProvider.fromFirestore(doc))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load providers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  GeoPoint _getMinGeoPoint() {
    // Calculate minimum bounds for distance filtering
    const radiusInKm = 10; // Search radius
    const kmInDegree = 111.32; // Approximate km per degree
    final lat = widget.location.latitude - (radiusInKm / kmInDegree);
    final lng =
        widget.location.longitude -
        (radiusInKm / (kmInDegree * cos(widget.location.latitude)));
    return GeoPoint(lat, lng);
  }

  GeoPoint _getMaxGeoPoint() {
    // Calculate maximum bounds for distance filtering
    const radiusInKm = 10; // Search radius
    const kmInDegree = 111.32; // Approximate km per degree
    final lat = widget.location.latitude + (radiusInKm / kmInDegree);
    final lng =
        widget.location.longitude +
        (radiusInKm / (kmInDegree * cos(widget.location.latitude)));
    return GeoPoint(lat, lng);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchValue =
        widget.searchQuery ?? widget.serviceCategory ?? 'Services';

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
                  ? 'Please select a date and time'
                  : 'Available on ${DateFormat('dd/MM/yyyy h:mm a').format(_selectedDateTime!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_providers.isEmpty) {
      return const Center(child: Text('No service providers found'));
    }

    return ListView.builder(
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        return _ServiceProviderCard(
          provider: _providers[index],
          onBook: () => _bookService(_providers[index]),
        );
      },
    );
  }

  void _bookService(ServiceProvider provider) {
    Navigator.pushNamed(
      context,
      AppRoutes.bookingPage,
      arguments: {
        'provider': provider,
        'dateTime': _selectedDateTime,
        'userLocation': widget.location,
      },
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onBook;

  const _ServiceProviderCard({required this.provider, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      provider.profilePictureUrl != null
                          ? NetworkImage(provider.profilePictureUrl!)
                          : null,
                  child:
                      provider.profilePictureUrl == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (provider.specialty.isNotEmpty)
                        Text(provider.specialty),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(' ${provider.rating.toStringAsFixed(1) ?? 'N/A'}'),
                const SizedBox(width: 16),
                const Icon(Icons.work, color: Colors.blue, size: 20),
                Text(' ${provider.completedJobs ?? 0} jobs'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBook,
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
