// File: homeconnect/data/providers/homeowner_firestore_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeownerFirestoreProvider {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1', // Match your function region
  );

  Future<List<ServiceProviderModel>> fetchRecommendedProviders({
    required String serviceCategory,
    required double homeownerLatitude,
    required double homeownerLongitude,
    double radiusKm = 10.0, // ✅ Default radius
    DateTime? desiredDateTime,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in.');
      }

      final HttpsCallable callable = _functions.httpsCallable(
        'getRecommendedProviders',
      );

      final Map<String, dynamic> requestData = {
        'serviceCategory': serviceCategory,
        'homeownerLatitude': homeownerLatitude,
        'homeownerLongitude': homeownerLongitude,
        'radiusKm': radiusKm, // ✅ Pass radius to Cloud Function
        'desiredDateTime': desiredDateTime?.toUtc().toIso8601String(),
      };

      print('DEBUG: Sending data to Cloud Function: $requestData');

      final result = await callable.call(requestData);

      final List<dynamic> providersData = result.data['providers'] ?? [];

      return providersData
          .map(
            (data) =>
                ServiceProviderModel.fromJson(Map<String, dynamic>.from(data)),
          )
          .toList();
    } on FirebaseFunctionsException catch (e) {
      print(
        '❌ Cloud Function error: code: ${e.code}, message: ${e.message}, details: ${e.details}',
      );
      throw Exception('Failed to fetch providers: ${e.message}');
    } catch (e) {
      print('❌ General error calling Cloud Function: $e');
      throw Exception(
        'An unexpected error occurred while fetching providers: $e',
      );
    }
  }

  // Other methods (e.g., fetchServiceProviderDetails) remain unchanged
  Future<Map<String, dynamic>?> fetchServiceProviderDetails(
    String providerId,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('service_providers')
              .doc(providerId)
              .get();
      return doc.data();
    } catch (e) {
      print('Error fetching service provider details: $e');
      return null;
    }
  }
}
