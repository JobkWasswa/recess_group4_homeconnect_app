import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:homeconnect/config/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _imageFile;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final user = _auth.currentUser;
    if (user == null) return;

    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentAddress = _addressController.text.trim();

    _firestore.collection('homeowners').doc(user.uid).get().then((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final hasChanges =
            currentName != (data['name'] ?? user.displayName ?? '') ||
            currentPhone != (data['phone'] ?? '') ||
            currentAddress != (data['address'] ?? '');

        if (_hasChanges != hasChanges) {
          setState(() => _hasChanges = hasChanges);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_auth.currentUser == null || !_hasChanges) return;

    setState(() => _isLoading = true);
    try {
      if (_imageFile != null) {
        await _uploadImage();
      }

      final updateData = <String, dynamic>{};
      final currentName = _nameController.text.trim();
      final currentPhone = _phoneController.text.trim();
      final currentAddress = _addressController.text.trim();

      final doc =
          await _firestore
              .collection('homeowners')
              .doc(_auth.currentUser!.uid)
              .get();
      final currentData = doc.data() ?? {};

      if (currentName !=
          (currentData['name'] ?? _auth.currentUser?.displayName ?? '')) {
        updateData['name'] = currentName;
        await _auth.currentUser!.updateDisplayName(currentName);
      }

      if (currentPhone != (currentData['phone'] ?? '')) {
        updateData['phone'] = currentPhone;
      }

      if (currentAddress != (currentData['address'] ?? '')) {
        updateData['address'] = currentAddress;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('homeowners')
            .doc(_auth.currentUser!.uid)
            .update(updateData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _isEditing = false;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || _auth.currentUser == null) return;

    try {
      final ref = _storage.ref().child(
        'profile_pictures/${_auth.currentUser!.uid}',
      );
      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();
      await _auth.currentUser!.updatePhotoURL(url);
      await _firestore
          .collection('homeowners')
          .doc(_auth.currentUser!.uid)
          .update({'photoUrl': url});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      rethrow;
    }
  }

  void _toggleEditMode(DocumentSnapshot snapshot) {
    if (!_isEditing) {
      final userData = snapshot.data() as Map<String, dynamic>;
      _nameController.text =
          userData['name'] ?? _auth.currentUser?.displayName ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
    } else if (_hasChanges) {
      _showSaveConfirmationDialog();
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _hasChanges = false;
        _imageFile = null;
      }
    });
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to save them?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditing = false;
                    _hasChanges = false;
                    _imageFile = null;
                  });
                },
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveChanges();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfilePicture(User? user) {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                _imageFile != null
                    ? FileImage(_imageFile!)
                    : (user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null),
            child:
                _imageFile == null && user?.photoURL == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    bool isEditable = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (!isEditable)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                value.isNotEmpty ? value : 'Not set',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: icon != null ? Icon(icon, size: 20) : null,
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: keyboardType,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream:
                _firestore.collection('homeowners').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return _isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed:
                        () =>
                            _isEditing
                                ? _saveChanges()
                                : _toggleEditMode(snapshot.data!),
                  );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore
                        .collection('homeowners')
                        .doc(user?.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('No profile data found'));
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Center(child: _buildProfilePicture(user)),
                        const SizedBox(height: 32),
                        _buildProfileField(
                          label: 'Name',
                          value:
                              _isEditing
                                  ? ''
                                  : userData['name'] ??
                                      user?.displayName ??
                                      'Not set',
                          isEditable: _isEditing,
                          controller: _nameController,
                          icon: Icons.person,
                        ),
                        _buildProfileField(
                          label: 'Email',
                          value: user?.email ?? 'Not available',
                        ),
                        _buildProfileField(
                          label: 'Phone',
                          value:
                              _isEditing ? '' : userData['phone'] ?? 'Not set',
                          isEditable: _isEditing,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone,
                        ),
                        _buildProfileField(
                          label: 'Address',
                          value:
                              _isEditing
                                  ? ''
                                  : userData['address'] ?? 'Not set',
                          isEditable: _isEditing,
                          controller: _addressController,
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await _auth.signOut();
                                if (mounted) {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed(AppRoutes.auth);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.red.shade300),
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
