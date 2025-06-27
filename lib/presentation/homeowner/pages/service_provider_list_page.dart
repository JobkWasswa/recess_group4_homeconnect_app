import 'package:flutter/material.dart';
import 'package:homeconnect/data/providers/homeowner_firestore_provider.dart';

class ServiceProviderListPage extends StatelessWidget {
  final String? searchQuery;
  final String? category;

  const ServiceProviderListPage({super.key, this.searchQuery, this.category});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final query = args != null ? args['query'] as String? : null;
    final category = args != null ? args['category'] as String? : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Available Professionals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: HomeownerFirestoreProvider().fetchProvidersBySkillOrCategory(
          query ?? category ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No service providers found.'));
          } else {
            final providers = snapshot.data!;
            return ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return ListTile(
                  title: Text(provider['name'] ?? 'Unnamed'),
                  subtitle: Text(
                    provider['skills']?.join(', ') ?? 'No skills listed',
                  ),
                  trailing: Text('${provider['rating'] ?? 'N/A'} ⭐'),
                  onTap: () {
                    // TODO: Navigate to detail page
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
// This page will display a list of service providers based on the selected category.