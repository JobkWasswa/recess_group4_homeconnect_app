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
      appBar: AppBar(title: const Text('My Profile')),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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

                Text(
                  "Name: ${data['name']}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text("Description: ${data['description']}"),
                const SizedBox(height: 10),

                const Text(
                  "Skills:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children:
                      (data['skills'] as List<dynamic>)
                          .map((skill) => Chip(label: Text(skill.toString())))
                          .toList(),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Location:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Address: ${location['address'] ?? 'N/A'}"),
                Text(
                  "Lat: ${location['lat'] ?? 'N/A'} | Lng: ${location['lng'] ?? 'N/A'}",
                ),

                const SizedBox(height: 20),
                const Text(
                  "Availability:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...availability.entries.map((entry) {
                  final day = entry.key;
                  final times = entry.value as Map<String, dynamic>;
                  return Text("$day: ${times['start']} - ${times['end']}");
                }).toList(),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(),
                      ),
                    );
                  },
                  child: Text('Edit profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
