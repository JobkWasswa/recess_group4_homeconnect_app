import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/presentation/service_provider/pages/profile _edit_screen.dart';

class ProfileDisplayScreen extends StatelessWidget {
  const ProfileDisplayScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    return FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileEditScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found.'));
          }

          final data = snapshot.data!.data()!;
          final location = data['location'] ?? {};
          final availability = data['availability'] ?? {};
          final categories = data['categories'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        data['profilePhoto'] != null
                            ? NetworkImage(data['profilePhoto'])
                            : null,
                    child:
                        data['profilePhoto'] == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const Divider(height: 30),

                const Text(
                  "Service Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      (categories as List<dynamic>)
                          .map((cat) => Chip(label: Text(cat.toString())))
                          .toList(),
                ),

                const Divider(height: 30),

                const Text(
                  "Location",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text("Address: ${location['address'] ?? 'N/A'}"),
                Text("Lat: ${location['lat'] ?? 'N/A'}"),
                Text("Lng: ${location['lng'] ?? 'N/A'}"),

                const Divider(height: 30),

                const Text(
                  "Availability",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                ...availability.entries.map((entry) {
                  final day = entry.key;
                  final times = entry.value as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text("$day: ${times['start']} - ${times['end']}"),
                  );
                }).toList(),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileEditScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
