import 'package:homeconnect/presentation/homeowner/pages/service_provider.dart';

class ApiService {
  Future<List<ServiceProvider>> getServiceProviders(
    Map<String, dynamic> filters,
  ) async {
    // Implement API call to get filtered service providers
    // This is a mock implementation
    await Future.delayed(const Duration(seconds: 1));

    return [
      ServiceProvider(
        id: '1',
        name: 'John Doe',
        specialty: 'Plumbing',
        rating: 4.5,
        completedJobs: 24,
        location: LatLng(37.7749, -122.4194),
        isAvailable: true,
        profession: 'Plumber',
      ),
      // Add more mock data
    ];
  }

  Future<void> submitRating({
    required String serviceId,
    required String providerId,
    required double rating,
  }) async {
    // Implement API call to submit rating
    await Future.delayed(const Duration(seconds: 1));
  }
}
