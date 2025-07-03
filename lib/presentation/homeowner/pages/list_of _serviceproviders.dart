import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/presentation/homeowner/pages/profile_display_for_client.dart'; // Import your profile screen

class ServiceProvidersList extends StatelessWidget {
  final String category;

  const ServiceProvidersList({super.key, required this.category});

  Future<List<DocumentSnapshot>> _fetchProviders() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('service_providers')
              .where('categories', arrayContains: category)
              .get();

      print('✅ Successfully fetched ${snapshot.docs.length} providers');
      return snapshot.docs;
    } catch (e) {
      print('❌ Firestore fetch error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Providers for $category')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No providers found.'));
          }

          final providers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final data = providers[index].data() as Map<String, dynamic>;
              final docId = providers[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProfileDisplayScreenForClient(userId: docId),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              data['profilePhoto'] != null
                                  ? NetworkImage(data['profilePhoto'])
                                  : null,
                          child:
                              data['profilePhoto'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Unnamed',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
