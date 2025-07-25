import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:homeconnect/data/models/services.dart'; // Assuming Selection() is here or imported elsewhere

// Import the new RatingReview model
import 'package:homeconnect/data/models/rating_review.dart'; // Make sure this path is correct
import 'package:geolocator/geolocator.dart'; // Import geolocator for location services

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Uint8List? _webImageBytes;
  io.File? _imageFile;
  String? _imageUrl;

  Map<String, dynamic> _availability = {};
  List<String> _selectedCategories = [];

  // New state variables for location
  GeoPoint? _currentLocation;
  String _locationStatus =
      'Loading location...'; // To displaying status to the user

  final picker = ImagePicker();

  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRatings(); // Load ratings when the screen initializes
    _getCurrentLocation(); // Load current location when the screen initializes
  }

  // --- Location Logic ---
  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationStatus = 'Getting current location...';
    });
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = 'Location services are disabled.';
      });
      // Consider showing a dialog to the user to enable services
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = 'Location permissions are denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      // Open app settings for the user to change permissions
      await Geolocator.openAppSettings();
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
        _locationStatus =
            'Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: ${e.toString()}';
      });
      print('Error getting location: $e'); // For debugging
    }
  }

  // --- Existing Profile Load Logic (updated to include location) ---
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(user.uid)
            .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      // Update from 'name' to 'profileInfo.name' as per the desired Firestore structure
      _nameController.text =
          data['profileInfo']?['name'] ?? ''; // Access nested name
      _descController.text = data['description'] ?? '';
      _imageUrl = data['profilePhoto'];

      // Load location if it exists
      if (data['location'] is GeoPoint) {
        _currentLocation = data['location'] as GeoPoint;
        _locationStatus =
            'Current saved location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}';
      } else {
        // If location is not a GeoPoint or missing, try to get current location
        _locationStatus = 'Location not set in profile. Getting current...';
        _getCurrentLocation();
      }

      _availability =
          (data['availability'] as Map<String, dynamic>?)?.map((key, value) {
            final startString = value['start'];
            final endString = value['end'];
            TimeOfDay? startTime;
            TimeOfDay? endTime;

            if (startString != null && startString.contains(':')) {
              final parts = startString.split(':');
              startTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            if (endString != null && endString.contains(':')) {
              final parts = endString.split(':');
              endTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }

            return MapEntry(key, {'start': startTime, 'end': endTime});
          }) ??
          {};
      _selectedCategories = List<String>.from(data['categories'] ?? []);
    });
  }

  Future<void> _loadRatings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch all ratings for the current service provider
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ratings_reviews')
            .where('serviceProviderId', isEqualTo: user.uid)
            .get();

    double sumRatings = 0;
    for (var doc in querySnapshot.docs) {
      try {
        final ratingReview = RatingReview.fromFirestore(doc);
        sumRatings += ratingReview.rating;
      } catch (e) {
        print('Error parsing rating review document: $e'); // For debugging
      }
    }

    setState(() {
      _totalReviews = querySnapshot.docs.length;
      _averageRating = _totalReviews > 0 ? sumRatings / _totalReviews : 0.0;
    });
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = io.File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null && _webImageBytes == null) return _imageUrl;

    final ref = FirebaseStorage.instance.ref(
      'profile_pictures/${DateTime.now().millisecondsSinceEpoch}',
    );

    if (kIsWeb && _webImageBytes != null) {
      await ref.putData(_webImageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      await ref.putFile(_imageFile!);
    }

    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one category.")),
      );
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set your current location.")),
      );
      return;
    }

    final updatedImageUrl = await _uploadProfileImage();

    Map<String, dynamic> availabilityDataForFirestore = {};
    _availability.forEach((day, value) {
      availabilityDataForFirestore[day] = {
        'start': value['start']?.format(context),
        'end': value['end']?.format(context),
      };
    });

    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .update({
          // Update to profileInfo.name as per desired Firestore structure
          'profileInfo': {'name': _nameController.text},
          'description': _descController.text,
          'profilePhoto': updatedImageUrl,
          'availability': availabilityDataForFirestore,
          'categories': _selectedCategories,
          'location': _currentLocation, // Save the GeoPoint location
        });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated.")));

    Navigator.pop(context, true);
  }

  void _showAvailabilityEditor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Availability'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final days = [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ];

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isAvailable =
                        _availability[day]?['start'] != null ||
                        _availability[day]?['end'] != null;

                    TimeOfDay? startTime = _availability[day]?['start'];
                    TimeOfDay? endTime = _availability[day]?['end'];

                    String formatTime(TimeOfDay? time) {
                      if (time == null) return '--:--';
                      final now = DateTime.now();
                      final dt = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                      return TimeOfDay.fromDateTime(dt).format(context);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day),
                            Switch(
                              value: isAvailable,
                              onChanged: (val) async {
                                setState(() {
                                  if (val) {
                                    _availability[day] = {
                                      'start': TimeOfDay(hour: 8, minute: 0),
                                      'end': TimeOfDay(hour: 17, minute: 0),
                                    };
                                  } else {
                                    _availability.remove(day);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (isAvailable)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _availability[day]['start'] = picked;
                                    });
                                  }
                                },
                                child: Text("Start: ${formatTime(startTime)}"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _availability[day]['end'] = picked;
                                    });
                                  }
                                },
                                child: Text("End: ${formatTime(endTime)}"),
                              ),
                            ],
                          ),
                        const Divider(),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectCategories() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (context) => Selection()),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _selectedCategories = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Use stretch for buttons
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _webImageBytes != null
                            ? MemoryImage(_webImageBytes!)
                            : (_imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_imageUrl != null
                                        ? NetworkImage(_imageUrl!)
                                        : null))
                                as ImageProvider?,
                    child:
                        (_webImageBytes == null &&
                                _imageFile == null &&
                                _imageUrl == null)
                            ? const Icon(Icons.person, size: 60)
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF6B4EEF),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Space above rating
            // Display Rating and Reviews here, below the profile picture and above the name field
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 5),
                Text(
                  _averageRating.toStringAsFixed(
                    1,
                  ), // Format to one decimal place
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '($_totalReviews reviews)',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20), // Space below rating

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6B4EEF)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6B4EEF)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // --- Location Update Section ---
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Current Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Text(_locationStatus), // Display location status/coordinates
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation, // Button to update location
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text(
                  "Update My Location",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Service Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: _selectCategories,
                  icon: const Icon(Icons.edit, color: Color(0xFF6B4EEF)),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Color(0xFF6B4EEF)),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _selectedCategories
                      .map(
                        (cat) => Chip(
                          label: Text(
                            cat,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF6B4EEF),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white70,
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedCategories.remove(cat);
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Availability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAvailabilityEditor,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  "Edit Availability",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
