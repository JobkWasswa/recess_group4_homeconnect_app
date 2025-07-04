// homeconnect/data/models/services.dart (or wherever your ServiceProvider model is defined)

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvider {
  final String uid;
  final String name;
  final String description;
  final List<String> categories;
  final List<String> skills;
  final String? profilePhoto;
  final Map<String, dynamic> location;
  final Map<String, dynamic> availability;
  final Timestamp createdAt;
  final double averageRating; // Initial value will be 0.0
  final int numberOfReviews; // Initial value will be 0
  // -----------------

  ServiceProvider({
    required this.uid,
    required this.name,
    required this.description,
    required this.categories,
    required this.skills,
    this.profilePhoto,
    required this.location,
    required this.availability,
    required this.createdAt,
    this.averageRating = 0.0, // Default to 0.0
    this.numberOfReviews = 0, // Default to 0
    // -----------------
  });

  factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ServiceProvider(
      uid: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      skills: List<String>.from(data['skills'] ?? []),
      profilePhoto: data['profilePhoto'],
      location: data['location'] ?? {},
      availability: data['availability'] ?? {},
      createdAt: data['createdAt'] ?? DateTime.timestamp(),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      numberOfReviews: (data['numberOfReviews'] ?? 0).toInt(),
      // -----------------
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'categories': categories,
      'skills': skills,
      'profilePhoto': profilePhoto,
      'location': location,
      'availability': availability,
      'createdAt': createdAt,
      'averageRating': averageRating,
      'numberOfReviews': numberOfReviews,
      // -----------------
    };
  }
}
