import 'dart:io' as io;
import 'dart:ui';
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
  final List<String> _skills = [];

  io.File? _profileImageFile; // for mobile & desktop
  Uint8List? _webImageBytes; // for web
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
  >>>>>>main

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
            locationAddress = "${place.locality}, ${place.country}";
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
        return;
      }

      // ✅ Validate category selection
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one category.")),
        );
        return;
      }

      final uid = user.uid;
      final imageUrl = await _uploadProfileImage();

      // ✅ Build availability data
      Map<String, dynamic> availabilityData = {};
      _availability.forEach((day, isAvailable) {
        if (isAvailable) {
          availabilityData[day] = {
            'start': _startTimes[day]?.format(context),
            'end': _endTimes[day]?.format(context),
          };
        }
      });

      // ✅ Save to service_providers collection
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(uid)
          .set({
            'name': _nameController.text,
            'description': _descController.text,
            'categories': _selectedCategories,
            'skills': _skills,
            'profilePhoto': imageUrl,
            'location': {
              'lat': _latitude,
              'lng': _longitude,
              'address': locationAddress,
            },
            'availability': availabilityData,
            'createdAt': Timestamp.now(),
          });

      // ✅ Save user reference under each selected category
      for (final category in _selectedCategories) {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category)
            .collection('users')
            .doc(uid)
            .set({
              'name': _nameController.text,
              'profilePhoto': imageUrl,
              'location': {
                'lat': _latitude,
                'lng': _longitude,
                'address': locationAddress,
              },
              'timestamp': Timestamp.now(),
            });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );

      // ✅ Navigate to dashboard
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
              backgroundColor: Colors.blue,
              child: Icon(Icons.edit, color: Colors.white, size: 18),
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
      appBar: AppBar(title: const Text('Create Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildProfileImage()),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Categories:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _selectCategories,
                  icon: const Icon(Icons.add),
                  label: const Text('Select Categories'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _selectedCategories
                      .map((category) => Chip(label: Text(category)))
                      .toList(),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Use Current Location"),
                  ),
                ),
              ],
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Location: $locationAddress",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Set Availability"),
              onPressed: _showAvailabilityDialog,
            ),
            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text("Save Profile", style: TextStyle(fontSize: 16)),
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
