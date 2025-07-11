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
  final int completedJobs; // ✅ New field

  ServiceProviderModel({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    required this.score,
    required this.completedJobs, // ✅ Include in constructor
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
      completedJobs: (data['completedJobs'] as int?) ?? 0, // ✅ Fetch from Cloud Function result
    );
  }

  /// Factory constructor for direct Firestore DocumentSnapshot reads
  factory ServiceProviderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceProviderModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['numberOfReviews'] as int?) ?? 0,
      distanceKm: null, // Not present in raw Firestore doc
      score: 0.0, // Not present in raw Firestore doc
      completedJobs: (data['completedJobs'] as int?) ?? 0, // ✅ Fetch from Firestore doc
    );
  }
}
