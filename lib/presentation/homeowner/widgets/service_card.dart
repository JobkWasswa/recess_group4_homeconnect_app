import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider.dart';
import 'package:homeconnect/services/location_service.dart';

class ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final LatLng? userLocation;
  final VoidCallback onBook;

  const ServiceProviderCard({
    super.key,
    required this.provider,
    this.userLocation,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildRatingStars(provider.rating),
              ],
            ),
            const SizedBox(height: 8),
            Text(provider.specialty),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.work, size: 16),
                const SizedBox(width: 4),
                Text('${provider.completedJobs} jobs completed'),
              ],
            ),
            if (userLocation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text('${_calculateDistance()} km away'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to profile
                  },
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onBook,
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  String _calculateDistance() {
    if (userLocation == null) {
      return 'N/A';
    }

    final distance = LocationService.calculateDistance(
      userLocation!.latitude,
      userLocation!.longitude,
      provider.location.latitude,
      provider.location.longitude,
    );

    return distance.toStringAsFixed(1);
  }
}
