// File: homeconnect/data/models/service_provider_modal.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String? profilePhoto;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  // Removed 'availableToday' as its presence in the filtered list implies availability
  final double score; // Add the calculated score

  ServiceProviderModel({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    required this.score,
  });

  // Factory constructor for deserializing from a Map (e.g., from Cloud Function result)
  // This assumes the 'id' is part of the data map returned by the Cloud Function
  factory ServiceProviderModel.fromJson(Map<String, dynamic> data) {
    return ServiceProviderModel(
      id:
          data['id']
              as String, // Expect 'id' to be present in the CF output map
      name: data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Use this if you are fetching a ServiceProvider from a direct Firestore DocumentSnapshot
  // This constructor is for when you are directly reading from Firestore,
  // where distance, availability, and score are NOT present and are computed by the CF.
  factory ServiceProviderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceProviderModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['numberOfReviews'] as int?) ?? 0,
      // These fields are calculated by the Cloud Function, so they won't be in a raw document snapshot.
      // Set them to null or default values when reading directly from Firestore.
      distanceKm: null,
      score: 0.0, // Default score when not from CF
    );
  }
}
