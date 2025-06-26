import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _skills = [];
  File? _profileImage;
  double? _latitude;
  double? _longitude;

  final picker = ImagePicker();
  String locationAddress = "Not picked";

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    final ref = FirebaseStorage.instance.ref(
      'profile_pictures/${DateTime.now().millisecondsSinceEpoch}',
    );
    await ref.putFile(_profileImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 2. Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    //  3. Get location using new LocationSettings
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // optional: minimum distance before update
    );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    // 4. Convert to address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];
    setState(() {
      locationAddress = "${place.locality}, ${place.country}";
    });
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

      final uid = user.uid;
      final imageUrl = await _uploadProfileImage();

      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(uid)
          .set({
            'name': _nameController.text,
            'description': _descController.text,
            'skills': _skills,
            'profilePhoto': imageUrl,
            'location': {
              'lat': _latitude,
              'lng': _longitude,
              'address': locationAddress,
            },
            'createdAt': Timestamp.now(),
          });

      if (!mounted) return; // Check if widget is still active
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    }
  }

  void _addSkillDialog() {
    final skillController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Skill'),
            content: TextField(controller: skillController),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _skills.add(skillController.text));
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileImage != null
                ? CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(_profileImage!),
                )
                : const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 40),
                ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Profile Picture'),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 6,
            ),
            Wrap(
              spacing: 6,
              children: _skills.map((s) => Chip(label: Text(s))).toList(),
            ),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text("Use Current Location"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addSkillDialog,
              child: const Text('Add Skill'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
