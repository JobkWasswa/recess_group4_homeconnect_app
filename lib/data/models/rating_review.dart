import 'package:cloud_firestore/cloud_firestore.dart';

class RatingReview {
  final String id;
  final String serviceProviderId;
  final String userId;
  final double rating;
  final String? reviewText;
  final Timestamp timestamp;

  RatingReview({
    required this.id,
    required this.serviceProviderId,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.timestamp,
  });

  factory RatingReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingReview(
      id: doc.id,
      serviceProviderId: data['serviceProviderId'] as String,
      userId: data['userId'] as String,
      rating: (data['rating'] as num).toDouble(), // Ensure double
      reviewText: data['reviewText'] as String?,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceProviderId': serviceProviderId,
      'userId': userId,
      'rating': rating,
      'reviewText': reviewText,
      'timestamp': timestamp,
    };
  }
}
