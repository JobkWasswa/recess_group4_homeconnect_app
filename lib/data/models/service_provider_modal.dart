import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String? profilePhoto;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final bool availableToday;
  final double score; // Add the calculated score

  ServiceProviderModel({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    required this.availableToday,
    required this.score,
  });

  factory ServiceProviderModel.fromMap(Map<String, dynamic> data, String id) {
    return ServiceProviderModel(
      id: id,
      name: data['name'] ?? 'Unnamed Provider', // Matches CF output 'name'
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating:
          (data['rating'] as num?)?.toDouble() ??
          0.0, // Matches CF output 'rating'
      reviewCount: data['reviewCount'] ?? 0, // Matches CF output 'reviewCount'
      distanceKm:
          (data['distanceKm'] as num?)
              ?.toDouble(), // Matches CF output 'distanceKm'
      availableToday:
          data['availableToday'] ?? false, // Matches CF output 'availableToday'
      score:
          (data['score'] as num?)?.toDouble() ??
          0.0, // Matches CF output 'score'
    );
  }

  // Use this if you are fetching a ServiceProvider from a direct Firestore DocumentSnapshot
  // This is corrected to match the fields shown in your "Screenshot (49).jpg"
  factory ServiceProviderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceProviderModel(
      id: doc.id,
      name:
          data['name'] ??
          'Unnamed Provider', // Direct 'name' field in Firestore
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating:
          (data['averageRating'] as num?)?.toDouble() ??
          0.0, // Direct 'averageRating' field in Firestore
      reviewCount:
          (data['numberOfReviews'] as int?) ??
          0, // Direct 'numberOfReviews' field in Firestore
      // Distance, availableToday, and score are calculated by Cloud Function,
      // so they are not directly available in the raw Firestore document unless explicitly stored for other purposes.
      distanceKm:
          null, // This is calculated by the Cloud Function, not directly from Firestore doc
      availableToday:
          data['availableToday'] ??
          false, // Assuming 'availableToday' exists directly in Firestore
      score:
          0.0, // This is calculated by the Cloud Function, not directly from Firestore doc
    );
  }
}
