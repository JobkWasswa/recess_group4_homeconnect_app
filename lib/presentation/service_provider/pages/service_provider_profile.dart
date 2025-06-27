import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are denied.');
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      setState(() => locationAddress = "${place.locality}, ${place.country}");
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

      if (!mounted) return;
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

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage:
              _profileImage != null ? FileImage(_profileImage!) : null,
          child:
              _profileImage == null ? const Icon(Icons.person, size: 60) : null,
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
                  'Skills:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addSkillDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Skill'),
                ),
              ],
            ),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _skills.map((skill) => Chip(label: Text(skill))).toList(),
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
