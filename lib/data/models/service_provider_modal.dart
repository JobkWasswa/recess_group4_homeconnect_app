import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String? profilePhoto;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final bool availableToday; // Add this field
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
      name: data['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      distanceKm: (data['distance'] as num?)?.toDouble(), // From Cloud Function
      availableToday: data['availableToday'] ?? false, // From Cloud Function
      score: (data['score'] as num?)?.toDouble() ?? 0.0, // From Cloud Function
    );
  }

  // If you also need to create from a Firestore DocumentSnapshot directly (less ideal after CF)
  factory ServiceProviderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceProviderModel(
      id: doc.id,
      name: data['profileInfo']?['name'] ?? 'Unnamed Provider',
      profilePhoto: data['profilePhoto'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['ratings']?['average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['ratings']?['count'] ?? 0,
      // Distance will be calculated by Cloud Function, so it might be null here
      distanceKm: null,
      availableToday: data['availableToday'] ?? false,
      score:
          0.0, // Score is calculated by CF, so not present directly in Firestore doc
    );
  }
}
