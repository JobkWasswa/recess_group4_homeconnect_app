import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:homeconnect/data/models/services.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  List<String> _selectedCategories = [];

  io.File? _profileImageFile;
  Uint8List? _webImageBytes;
  double? _latitude;
  double? _longitude;
  final picker = ImagePicker();
  String locationAddress = "Not picked";
  final Map<String, bool> _availability = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  final Map<String, TimeOfDay?> _startTimes = {};
  final Map<String, TimeOfDay?> _endTimes = {};

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _profileImageFile = null;
        });
      } else {
        setState(() {
          _profileImageFile = io.File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    final ref = FirebaseStorage.instance.ref(
      'profile_pictures/${DateTime.now().millisecondsSinceEpoch}',
    );

    if (kIsWeb && _webImageBytes != null) {
      await ref.putData(_webImageBytes!);
    } else if (!kIsWeb && _profileImageFile != null) {
      await ref.putFile(_profileImageFile!);
    } else {
      return null;
    }

    return await ref.getDownloadURL();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            locationAddress =
                "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
          });
        } else {
          setState(() {
            locationAddress = "Location found, but no address.";
          });
        }
      } catch (e) {
        setState(() {
          locationAddress = "Coordinates: $_latitude, $_longitude";
        });
        debugPrint("Failed to get placemark: $e");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location error: $e")));
    }
  }

  Future<void> _saveProfile() async {
    print("Save profile button pressed");
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
        return;
      }

      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one category.")),
        );
        return;
      }

      final uid = user.uid;
      final imageUrl = await _uploadProfileImage();

      Map<String, dynamic> availabilityData = {};
      _availability.forEach((day, isAvailable) {
        if (isAvailable) {
          availabilityData[day] = {
            'start': _startTimes[day]?.format(context),
            'end': _endTimes[day]?.format(context),
          };
        }
      });

      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(uid)
          .set({
            'name': _nameController.text,
            'description': _descController.text,
            'categories': _selectedCategories,
            'profilePhoto': imageUrl,
            'location': GeoPoint(_latitude!, _longitude!),
            'availability': availabilityData,
            'createdAt': Timestamp.now(),
            'averageRating': 0.0,
            'numberOfReviews': 0,
          });

      for (final category in _selectedCategories) {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category)
            .collection('users')
            .doc(uid)
            .set({
              'name': _nameController.text,
              'profilePhoto': imageUrl,
              'location': GeoPoint(_latitude!, _longitude!),
              'address': locationAddress,
              'timestamp': Timestamp.now(),
              'averageRating': 0.0,
              'numberOfReviews': 0,
            });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.serviceProviderDashboard,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage:
              kIsWeb
                  ? (_webImageBytes != null
                      ? MemoryImage(_webImageBytes!)
                      : null)
                  : (_profileImageFile != null
                      ? FileImage(_profileImageFile!)
                      : null),
          child:
              (kIsWeb && _webImageBytes == null) ||
                      (!kIsWeb && _profileImageFile == null)
                  ? const Icon(Icons.person, size: 60)
                  : null,
        ),
        Positioned(
          child: InkWell(
            onTap: _pickImage,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(
                0xFF6B4EEF,
              ), // Purple color from screenshot
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ), // Changed to camera icon
            ),
          ),
        ),
      ],
    );
  }

  void _showAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Availability'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        _availability.keys.map((day) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(day),
                                  Switch(
                                    value: _availability[day] ?? false,
                                    onChanged: (val) {
                                      setState(() {
                                        _availability[day] = val;
                                        if (!val) {
                                          _startTimes.remove(day);
                                          _endTimes.remove(day);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_availability[day] == true) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(
                                            () => _startTimes[day] = picked,
                                          );
                                        }
                                      },
                                      child: Text(
                                        _startTimes[day] != null
                                            ? "Start: ${_startTimes[day]!.format(context)}"
                                            : "Set Start Time",
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(
                                            () => _endTimes[day] = picked,
                                          );
                                        }
                                      },
                                      child: Text(
                                        _endTimes[day] != null
                                            ? "End: ${_endTimes[day]!.format(context)}"
                                            : "Set End Time",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(), // Added a divider for better separation between days
                            ],
                          );
                        }).toList(),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // You can also validate start < end here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Availability set.")),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectCategories() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => Selection(),
      ), // Assuming 'Selection' is your category selection page
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
          'Create Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ), // Bold title
        centerTitle: true, // Center app bar title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProfileImage()),
            const SizedBox(height: 30), // Increased space after profile photo

            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Space before text field

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  // Consistent border
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B4EEF),
                  ), // Purple focus border
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
                hintText: 'Describe your services...',
                border: OutlineInputBorder(
                  // Consistent border
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B4EEF),
                  ), // Purple focus border
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20), // More space before skills/categories

            const Text(
              'Skills & Expertise', // Added section title
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Moved "Select Categories" into a Row with "Add Skill" if needed,
            // or just kept it standalone. Assuming "Skills & Expertise" is for categories.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Categories:', // Kept for clarity, but you might rephrase or remove
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  // Changed to ElevatedButton.icon for "Add Skill" look
                  onPressed: _selectCategories,
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ), // White icon
                  label: const Text(
                    'Add Skill',
                    style: TextStyle(color: Colors.white),
                  ), // White text
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4CAF50,
                    ), // Green color from screenshot for "Add Skill"
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _selectedCategories
                      .map(
                        (category) => Chip(
                          label: Text(
                            category,
                            style: const TextStyle(color: Colors.white),
                          ), // White text on chip
                          backgroundColor: const Color(
                            0xFF6B4EEF,
                          ), // Purple background for chip
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white70,
                          ), // Optional: add delete icon
                          onDeleted: () {
                            // Optional: allow deletion of chips
                            setState(() {
                              _selectedCategories.remove(category);
                            });
                          },
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: 10), // Increased space before Location

            const Text(
              'Location', // Section title
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            SizedBox(
              // Wrapped in SizedBox for consistent width
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ), // Adjusted icon
                label: const Text(
                  "Use Current Location",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ), // Green color from screenshot
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ), // Consistent padding
                ),
              ),
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0), // More space
                child: Text(
                  "Location: $locationAddress",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ), // Slightly larger font
                ),
              ),
            const SizedBox(height: 30), // Increased space before Availability

            const Text(
              'Availability', // Section title
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              // Wrapped in SizedBox for consistent width
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  "Set Your Availability",
                  style: TextStyle(color: Colors.white),
                ), // Text from screenshot
                onPressed: _showAvailabilityDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EEF), // Purple button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ), // Increased space before Create Profile button

            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EEF), // Purple button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Rounded corners
                    ),
                    elevation: 5, // Subtle shadow
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                    ), // Increased padding for a taller button
                    child: Text(
                      "Create Profile",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ), // Bold and white text
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
