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
  final double score;
  final int completedJobs;
  final String? email; // ✅ NEW: Added email field

  ServiceProviderModel({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    required this.score,
    required this.completedJobs,
    this.email, // ✅ Include in constructor
  });

  /// Factory constructor for deserializing from a Cloud Function result (via Map)
  factory ServiceProviderModel.fromJson(Map<String, dynamic> data) {
    return ServiceProviderModel(
      id: data['id'] as String,
      name: data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      completedJobs: (data['completedJobs'] as int?) ?? 0,
      email: data['email'] as String?, // ✅ Fetch from Cloud Function result
    );
  }

  /// Factory constructor for direct Firestore DocumentSnapshot reads
  factory ServiceProviderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ServiceProviderModel(
      id: doc.id,
      name: data['fullName'] ?? data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'] as String?,
      categories:
          (data['categories'] is List)
              ? List<String>.from(data['categories'])
              : <String>[],
      rating:
          (data['averageRating'] is num)
              ? (data['averageRating'] as num).toDouble()
              : 0.0,
      reviewCount:
          data['numberOfReviews'] is int ? data['numberOfReviews'] as int : 0,
      distanceKm: null, // calculate or assign later if needed
      score: 0.0, // same as above
      completedJobs:
          data['completedJobs'] is int ? data['completedJobs'] as int : 0,
      email: data['email'] as String?,
    );
  }
}
