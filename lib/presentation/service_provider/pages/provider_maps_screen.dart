import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:permission_handler/permission_handler.dart'; 

class ProviderMapsScreen extends StatefulWidget {
  const ProviderMapsScreen({super.key});

  @override
  State<ProviderMapsScreen> createState() => _ProviderMapsScreenState();
}

class _ProviderMapsScreenState extends State<ProviderMapsScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isLoadingMap = true;
  String? _errorMessage;

  // Default camera position if current location isn't available
  static const LatLng _kDefaultInitialPosition = LatLng(
    0.3150,
    32.5828,
  ); // Kampala, Uganda

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    try {
      await _checkLocationPermission();
      await _getCurrentLocation(); // Try to get current location first
      await _loadActiveJobLocations();
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading map data: $e";
        _isLoadingMap = false;
      });
      print("Error initializing map data: $e");
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permissions are permanently denied. Please enable them from settings.",
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 12),
        );
      }
    } catch (e) {
      print("Could not get current location: $e");
      // Fallback to default or just proceed without current location
    }
  }

  Future<void> _loadActiveJobLocations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _errorMessage = "User not logged in.";
      });
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: userId)
              .where('status', whereIn: ['confirmed', 'in_progress'])
              .get();

      if (mounted) {
        setState(() {
          _markers.clear(); // Clear existing markers
          int markerIdCounter = 0; // To ensure unique marker IDs

          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            final latitude =
                data['latitude']; // Assuming separate lat/lng fields
            final longitude = data['longitude'];

            if (latitude != null && longitude != null) {
              final LatLng position = LatLng(latitude, longitude);
              final String clientName = data['clientName'] ?? 'Unknown Client';
              final String jobType =
                  (data['categories'] is List && data['categories'].isNotEmpty)
                      ? data['categories'][0].toString()
                      : (data['categories']?.toString() ?? 'Service');

              _markers.add(
                Marker(
                  markerId: MarkerId(
                    'job_${doc.id}_${markerIdCounter++}',
                  ), // Unique ID
                  position: position,
                  infoWindow: InfoWindow(
                    title: jobType,
                    snippet: 'Client: $clientName',
                  ),
                ),
              );
            }
          }

          // If no current location, and there are active jobs,
          // center the map on the first job location (if available)
          if (_currentLocation == null && _markers.isNotEmpty) {
            final firstMarkerPosition = _markers.first.position;
            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(firstMarkerPosition, 12),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching job locations: $e";
        });
      }
      print("Error fetching job locations: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // If _currentLocation or markers are already loaded, center map
    if (_currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 12),
      );
    } else if (_markers.isNotEmpty) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_markers.first.position, 12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service Area Map'),
        backgroundColor: const Color(0xFF9333EA),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoadingMap
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      if (_errorMessage!.contains("permissions"))
                        ElevatedButton(
                          onPressed: () {
                            openAppSettings(); // From permission_handler package
                          },
                          child: const Text('Open App Settings'),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoadingMap = true;
                            _errorMessage = null;
                          });
                          _initializeMapData(); // Retry loading
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? _kDefaultInitialPosition,
                  zoom: 10.0,
                ),
                markers: _markers,
                myLocationEnabled:
                    _currentLocation !=
                    null, // Show blue dot if location is available
                myLocationButtonEnabled: _currentLocation != null,
              ),
    );
  }
}
