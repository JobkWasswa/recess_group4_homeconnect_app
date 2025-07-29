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

  static const LatLng _kDefaultInitialPosition = LatLng(
    0.3150,
    32.5828,
  ); // Kampala

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    try {
      await _checkLocationPermission();
      await _getCurrentLocation();
      await _loadActiveJobLocations();
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading map data: $e";
      });
      print("❌ Error initializing map data: $e");
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
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      print("📍 CurrentLocation: $_currentLocation");
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 12),
        );
      }
    } catch (e) {
      print("⚠️ Could not get current location: $e");
    }
  }

  Future<void> _loadActiveJobLocations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _errorMessage = "User not logged in.");
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: userId)
              .where('status', whereIn: ['confirmed', 'in_progress'])
              .get();

      print(
        "🔍 Found ${querySnapshot.docs.length} booking(s) for provider $userId",
      );

      _markers.clear();
      int markerIdCounter = 0;
      final homeIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print(" • doc ${doc.id} → $data");

        if (data['location'] != null && data['location'] is GeoPoint) {
          GeoPoint geoPoint = data['location'];
          double lat = geoPoint.latitude;
          double lng = geoPoint.longitude;
          print("   ✅ Location: lat=$lat, lng=$lng");

          final pos = LatLng(lat, lng);
          final clientName = data['clientName'] ?? 'Unknown';
          final jobType =
              (data['categories'] is List && data['categories'].isNotEmpty)
                  ? data['categories'][0].toString()
                  : (data['selectedCategory']?.toString() ?? 'Service');

          _markers.add(
            Marker(
              markerId: MarkerId('job_${doc.id}_${markerIdCounter++}'),
              position: pos,
              icon: homeIcon,
              infoWindow: InfoWindow(
                title: jobType,
                snippet: 'Client: $clientName',
              ),
            ),
          );
        } else {
          print("⚠️ Skipping: missing or invalid location for ${doc.id}");
        }
      }

      print("🏷️ Added ${_markers.length} marker(s) to the map");

      if (_currentLocation == null && _markers.isNotEmpty) {
        final first = _markers.first.position;
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(first, 12));
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching job locations: $e");
      print("❌ Error fetching job locations: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
                  padding: const EdgeInsets.all(16),
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
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (_errorMessage!.contains("permissions"))
                        ElevatedButton(
                          onPressed: openAppSettings,
                          child: const Text('Open App Settings'),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoadingMap = true;
                            _errorMessage = null;
                          });
                          _initializeMapData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? _kDefaultInitialPosition,
                        zoom: 10,
                      ),
                      markers: _markers,
                      myLocationEnabled: _currentLocation != null,
                      myLocationButtonEnabled: _currentLocation != null,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children:
                          _markers.map((m) {
                            return ListTile(
                              leading: const Icon(
                                Icons.place,
                                color: Colors.green,
                              ),
                              title: Text(m.markerId.value),
                              subtitle: Text(
                                '${m.position.latitude}, ${m.position.longitude}',
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
    );
  }
}
