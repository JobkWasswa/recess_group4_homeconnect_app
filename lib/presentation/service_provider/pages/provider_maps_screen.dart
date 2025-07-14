// homeconnect/presentation/service_provider/pages/provider_maps_screen.dart
import 'package:flutter/material.dart';
import 'package:Maps_flutter/Maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:homeconnect/data/models/booking.dart'; // Your Booking model
import 'package:homeconnect/data/repositories/service_provider_repo.dart'; // Your SP repo

class ProviderMapsScreen extends StatefulWidget {
  const ProviderMapsScreen({super.key});

  @override
  State<ProviderMapsScreen> createState() => _ProviderMapsScreenState();
}

class _ProviderMapsScreenState extends State<ProviderMapsScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _listenForActiveBookings();
    }
  }

  void _listenForActiveBookings() {
    // Using your existing ServiceProviderRepository for consistency
    ServiceProviderRepository(firestore: FirebaseFirestore.instance)
        .getActiveBookings(_currentUserId!)
        .listen((List<Booking> activeBookings) {
          _updateMarkers(activeBookings);
        })
        .onError((error) {
          print("Error fetching active bookings for map: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading bookings for map: $error')),
          );
        });
  }

  void _updateMarkers(List<Booking> bookings) {
    setState(() {
      _markers.clear();
      for (var booking in bookings) {
        // Only show markers for confirmed or in-progress jobs
        if (booking.status == Booking.confirmed ||
            booking.status == Booking.inProgress) {
          _markers.add(
            Marker(
              markerId: MarkerId(booking.bookingId!),
              position: LatLng(
                booking.location.latitude,
                booking.location.longitude,
              ),
              infoWindow: InfoWindow(
                title: booking.clientName,
                snippet: '${booking.categories.join(', ')} - ${booking.status}',
                onTap:
                    () => _launchGoogleMaps(
                      booking.location.latitude,
                      booking.location.longitude,
                    ),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ), // Use a distinct color
            ),
          );
        }
      }
    });
    // Optional: Animate camera to show all markers or the first active one
    if (bookings.isNotEmpty && _mapController != null) {
      final activeBookings =
          bookings
              .where(
                (b) =>
                    b.status == Booking.confirmed ||
                    b.status == Booking.inProgress,
              )
              .toList();
      if (activeBookings.isNotEmpty) {
        // Try to show the first active job, or adjust zoom to fit all
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              activeBookings.first.location.latitude,
              activeBookings.first.location.longitude,
            ),
            14.0, // A good zoom level for a single job
          ),
        );
      }
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'google.navigation:q=$latitude,$longitude&mode=d',
    ); // 'd' for driving, 'w' for walking
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback for web or if app is not installed
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Locations')),
        body: const Center(child: Text('Please log in to view job locations.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Job Locations'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(0.347596, 32.582520), // Default to Kampala, Uganda
          zoom: 12.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true, // Show user's current location on map
        myLocationButtonEnabled: true, // Button to recenter on user's location
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
