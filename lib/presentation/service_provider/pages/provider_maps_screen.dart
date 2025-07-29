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
      setState(() => _errorMessage = "Error loading map data: $e");
      debugPrint("❌ Error initializing map data: $e");
    } finally {
      setState(() => _isLoadingMap = false);
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
      debugPrint("📍 CurrentLocation: $_currentLocation");
    } catch (e) {
      debugPrint("⚠️ Could not get current location: $e");
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

      debugPrint(
        "🔍 Found ${querySnapshot.docs.length} booking(s) for provider $userId",
      );

      _markers.clear();
      int markerIdCounter = 0;
      LatLngBounds? bounds;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        debugPrint(" • doc ${doc.id} → $data");

        if (data['location'] is GeoPoint && data['endDateTime'] != null) {
          final GeoPoint geo = data['location'];
          final DateTime endDateTime =
              (data['endDateTime'] as Timestamp).toDate();

          if (DateTime.now().isAfter(endDateTime)) continue; // ⛔ Skip past jobs

          final pos = LatLng(geo.latitude, geo.longitude);
          final clientName = data['clientName'] ?? 'Unknown';
          final category =
              (data['categories'] is List && data['categories'].isNotEmpty)
                  ? data['categories'][0].toString()
                  : (data['selectedCategory']?.toString() ?? 'Service');

          final marker = Marker(
            markerId: MarkerId('job_${doc.id}_${markerIdCounter++}'),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: category,
              snippet: 'Client: $clientName',
            ),
          );
          _markers.add(marker);

          bounds =
              bounds == null
                  ? LatLngBounds(southwest: pos, northeast: pos)
                  : _extendBounds(bounds, pos);
        }
      }

      debugPrint("🏷️ Added ${_markers.length} marker(s) to the map");

      // Auto-fit markers
      if (_markers.isNotEmpty && mapController != null && bounds != null) {
        await Future.delayed(
          Duration(milliseconds: 500),
        ); // Allow map to render
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } else if (_currentLocation != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 12),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching job locations: $e");
      debugPrint("❌ Error fetching job locations: $e");
    }
  }

  LatLngBounds _extendBounds(LatLngBounds bounds, LatLng pos) {
    final swLat =
        bounds.southwest.latitude < pos.latitude
            ? bounds.southwest.latitude
            : pos.latitude;
    final swLng =
        bounds.southwest.longitude < pos.longitude
            ? bounds.southwest.longitude
            : pos.longitude;
    final neLat =
        bounds.northeast.latitude > pos.latitude
            ? bounds.northeast.latitude
            : pos.latitude;
    final neLng =
        bounds.northeast.longitude > pos.longitude
            ? bounds.northeast.longitude
            : pos.longitude;
    return LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );
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
              ? _buildErrorUI()
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
                              title: Text(
                                m.infoWindow.snippet ?? m.markerId.value,
                              ),
                              subtitle: Text(
                                '${m.position.latitude.toStringAsFixed(6)}, ${m.position.longitude.toStringAsFixed(6)}',
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
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
    );
  }
}
