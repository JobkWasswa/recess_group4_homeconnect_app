import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:homeconnect/data/models/service_provider_modal.dart';

class HomeownerFirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // This method will now call the Cloud Function
  Future<List<ServiceProviderModel>> fetchRecommendedProviders({
    required String serviceCategory,
    required double homeownerLatitude,
    required double homeownerLongitude,
    DateTime? desiredDateTime, // Optional parameter for availability
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'getRecommendedProviders',
      );
      final result = await callable.call(<String, dynamic>{
        'serviceCategory': serviceCategory,
        'homeownerLatitude': homeownerLatitude,
        'homeownerLongitude': homeownerLongitude,
        'desiredDateTime':
            desiredDateTime?.toIso8601String(), // Pass as ISO string
      });

      final List<dynamic> providersData = result.data['providers'] ?? [];
      return providersData
          .map((data) => ServiceProviderModel.fromMap(data, data['id']))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      print(
        '❌ Cloud Function error: code: ${e.code}, message: ${e.message}, details: ${e.details}',
      );
      // Handle specific error codes if needed, e.g., show a user-friendly message
      throw Exception('Failed to fetch providers: ${e.message}');
    } catch (e) {
      print('❌ General error calling Cloud Function: $e');
      throw Exception('An unexpected error occurred while fetching providers.');
    }
  }

  // You might still keep other Firestore direct access methods if needed for other parts of the app
  // e.g., fetching a single provider's detailed profile
  Future<Map<String, dynamic>?> fetchServiceProviderDetails(
    String providerId,
  ) async {
    try {
      final doc =
          await _firestore
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
