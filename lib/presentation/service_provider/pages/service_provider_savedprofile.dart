import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:homeconnect/presentation/service_provider/pages/profile _edit_screen.dart';

class ProfileDisplayScreen extends StatefulWidget {
  const ProfileDisplayScreen({super.key});

  @override
  State<ProfileDisplayScreen> createState() => _ProfileDisplayScreenState();
}

class _ProfileDisplayScreenState extends State<ProfileDisplayScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profileFuture;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _profileFuture = FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .get()
        .then((doc) {
          final geo = doc.data()?['location'] as GeoPoint?;
          if (geo != null) {
            _getAddressFromGeoPoint(geo).then((addr) {
              setState(() {
                _resolvedAddress = addr;
              });
            });
          }

          // Fetch averageRating and numberOfReviews directly
          setState(() {
            _averageRating = doc.data()?['averageRating']?.toDouble() ?? 0.0;
            _totalReviews = doc.data()?['numberOfReviews'] ?? 0;
          });

          debugPrint('Average Rating: $_averageRating');
          debugPrint('Total Reviews: $_totalReviews');

          return doc;
        });
  }

  Future<void> _loadRatings(String serviceProviderId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ratings_reviews')
            .where('serviceProviderId', isEqualTo: serviceProviderId)
            .get();

    double sumRatings = 0;
    for (var doc in querySnapshot.docs) {
      final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      sumRatings += rating;
    }

    setState(() {
      _totalReviews = querySnapshot.docs.length;
      _averageRating = _totalReviews > 0 ? sumRatings / _totalReviews : 0.0;
    });
  }

  Future<String> _getAddressFromGeoPoint(GeoPoint geoPoint) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        geoPoint.latitude,
        geoPoint.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      return 'Address not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
              if (result == true) {
                setState(() {
                  _loadProfile();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile not found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final GeoPoint? location = data['location'];
          final availability = data['availability'] ?? {};
          final categories = data['categories'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage:
                            data['profilePhoto'] != null
                                ? NetworkImage(data['profilePhoto'])
                                : null,
                        child:
                            data['profilePhoto'] == null
                                ? Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.blue.shade800,
                                )
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    data['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 5),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '($_totalReviews reviews)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    data['email'] ?? '',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(
                  context,
                  "Service Categories",
                  Icons.category,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children:
                      (categories as List<dynamic>)
                          .map(
                            (cat) => Chip(
                              label: Text(cat.toString()),
                              backgroundColor: Colors.lightBlue.shade100,
                              labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                          )
                          .toList(),
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(context, "Location", Icons.location_on),
                const SizedBox(height: 10),
                _buildProfileDetailRow(
                  "Address",
                  _resolvedAddress ?? 'Loading address...',
                  Icons.pin_drop,
                ),
                _buildProfileDetailRow(
                  "Latitude",
                  location?.latitude.toString() ?? 'N/A',
                  Icons.map,
                ),
                _buildProfileDetailRow(
                  "Longitude",
                  location?.longitude.toString() ?? 'N/A',
                  Icons.map,
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(context, "Availability", Icons.access_time),
                const SizedBox(height: 10),
                if (availability.isNotEmpty)
                  ...availability.entries.map((entry) {
                    final day = entry.key;
                    final times = entry.value as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$day: ${times['start'] ?? 'N/A'} - ${times['end'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                else
                  const Text(
                    "No availability set.",
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
