import 'package:flutter/material.dart';

class ServiceProviderDetailPage extends StatelessWidget {
  
  const ServiceProviderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider['name'] ?? 'Provider Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${provider['name'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Skills: ${provider['skills']?.join(', ') ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
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