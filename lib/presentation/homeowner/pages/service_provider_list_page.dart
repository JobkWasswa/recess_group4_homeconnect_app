import 'package:flutter/material.dart';

class ServiceProviderListPage extends StatelessWidget {
  const ServiceProviderListPage({Key? key, required String category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Professionals'),
      ),
      body: Center(
        child: Text('List of service providers will appear here.'),
      ),
    );
  }
}
// This page will display a list of service providers based on the selected category.