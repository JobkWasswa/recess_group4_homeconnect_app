import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _skills = [];

  Uint8List? _webImageBytes;
  io.File? _imageFile;
  String? _imageUrl;

  Map<String, dynamic> _availability = {};

  final picker = ImagePicker();

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
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _skills.addAll(List<String>.from(data['skills'] ?? []));
      _imageUrl = data['profilePhoto'];
      _availability = data['availability'] ?? {};
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

    final updatedImageUrl = await _uploadProfileImage();

    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .update({
          'name': _nameController.text,
          'description': _descController.text,
          'skills': _skills,
          'profilePhoto': updatedImageUrl,
          'availability': _availability,
        });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated.")));
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
                    final isAvailable = _availability[day] != null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day),
                            Switch(
                              value: isAvailable,
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    _availability[day] = {
                                      'start': '08:00 AM',
                                      'end': '05:00 PM',
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
                              Text("Start: ${_availability[day]['start']}"),
                              Text("End: ${_availability[day]['end']}"),
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Skills",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addSkillDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          onDeleted: () {
                            setState(() => _skills.remove(skill));
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAvailabilityEditor,
              icon: const Icon(Icons.calendar_today),
              label: const Text("Edit Availability"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
