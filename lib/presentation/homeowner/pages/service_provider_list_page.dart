import 'package:flutter/material.dart';
import 'package:homeconnect/data/providers/homeowner_firestore_provider.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:homeconnect/presentation/homeowner/pages/list_of _serviceproviders.dart'; // Import your ServiceProvidersList
import 'package:geolocator/geolocator.dart'; // Needed for getting user location
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for GeoPoint

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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
        appBar: AppBar(title: Text('Available Professionals')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Getting your location to find nearby providers...'),
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
        appBar: AppBar(title: Text('Available Professionals')),
        body: Center(
          child: Text(
            'Could not determine your location. Cannot find nearby providers.',
          ),
        ),
      );
    }

    // Now navigate to ServiceProvidersList, passing the category and GeoPoint
    return ServiceProvidersList(
      category: searchValue,
      userLocation: _userCurrentLocation!,
    );
  }
}
