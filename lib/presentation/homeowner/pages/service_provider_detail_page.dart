import 'package:flutter/material.dart';

class ServiceProviderDetailPage extends StatelessWidget {
  const ServiceProviderDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Details'),
      ),
      body: const Center(
        child: Text('Detail page content will go here.'),
      ),
    );
  }
}
