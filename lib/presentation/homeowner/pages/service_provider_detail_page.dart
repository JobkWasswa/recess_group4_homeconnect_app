import 'package:flutter/material.dart';

class ServiceProviderDetailPage extends StatelessWidget {
  const ServiceProviderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Expecting a map with at least: name, skills (List<String>), rating (num)
    final provider =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider['name'] ?? 'Service Provider Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              'Name: ${provider['name'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Skills
            Text(
              'Skills: ${(provider['skills'] as List?)?.join(", ") ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Rating
            Text(
              'Rating: ${provider['rating']?.toString() ?? 'N/A'} ⭐',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
