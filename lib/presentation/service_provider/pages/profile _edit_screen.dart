import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:homeconnect/data/models/services.dart'; // Assuming Selection() is here or imported elsewhere

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

  Map<String, dynamic> _availability =
      {}; // This map should be structured to hold TimeOfDay for consistency
  List<String> _selectedCategories = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
      _imageUrl = data['profilePhoto'];
      // Reconstruct availability map for TimeOfDay objects from string
      _availability =
          (data['availability'] as Map<String, dynamic>?)?.map((key, value) {
            final startString = value['start'];
            final endString = value['end'];
            // You might need a helper to parse HH:mm AM/PM to TimeOfDay
            // For now, assuming you store them in HH:mm format for direct parsing
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

    final updatedImageUrl = await _uploadProfileImage();

    // Prepare availability data for Firestore
    Map<String, dynamic> availabilityDataForFirestore = {};
    _availability.forEach((day, value) {
      availabilityDataForFirestore[day] = {
        'start': value['start']?.format(
          context,
        ), // Convert TimeOfDay back to string
        'end': value['end']?.format(context),
      };
    });

    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .update({
          'name': _nameController.text,
          'description': _descController.text,
          'profilePhoto': updatedImageUrl,
          'availability': availabilityDataForFirestore, // Use the prepared map
          'categories': _selectedCategories,
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
                    // Check if day exists in _availability and has start/end times
                    final isAvailable =
                        _availability[day]?['start'] != null ||
                        _availability[day]?['end'] != null;

                    TimeOfDay? startTime = _availability[day]?['start'];
                    TimeOfDay? endTime = _availability[day]?['end'];

                    // Helper to format TimeOfDay
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
                      return TimeOfDay.fromDateTime(
                        dt,
                      ).format(context); // Use context for locale format
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
                                      'start': TimeOfDay(
                                        hour: 8,
                                        minute: 0,
                                      ), // Default start
                                      'end': TimeOfDay(
                                        hour: 17,
                                        minute: 0,
                                      ), // Default end
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
                        const Divider(), // Added a divider
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
        ), // Bold title
        centerTitle: true, // Center app bar title
      ),
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
                        backgroundColor: Color(0xFF6B4EEF), // Purple color
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ), // Camera icon
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Increased space

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Service Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  // Keeping TextButton.icon as per your original for Edit
                  onPressed: _selectCategories,
                  icon: const Icon(
                    Icons.edit,
                    color: Color(0xFF6B4EEF),
                  ), // Purple icon
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Color(0xFF6B4EEF)),
                  ), // Purple text
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
              // Align left for "Availability" text
              alignment: Alignment.centerLeft,
              child: const Text(
                'Availability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              // Wrapped in SizedBox for consistent width
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAvailabilityEditor,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  "Edit Availability",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EEF), // Purple button
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
                  backgroundColor: const Color(0xFF6B4EEF), // Purple button
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
