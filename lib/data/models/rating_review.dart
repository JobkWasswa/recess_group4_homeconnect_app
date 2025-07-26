// In your rating_review.dart file
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingReview {
  final String id;
  final String serviceProviderId;
  final String clientId;
  final double rating;
  final String reviewText;
  final Timestamp? timestamp;
  String? clientName; // Make it mutable or add it to constructor

  RatingReview({
    required this.id,
    required this.serviceProviderId,
    required this.clientId,
    required this.rating,
    this.reviewText = '',
    this.timestamp,
    this.clientName, // Include in constructor
  });

  factory RatingReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RatingReview(
      id: doc.id,
      serviceProviderId: data['serviceProviderId'] ?? '',
      clientId: data['clientId'] ?? '',
      rating:
          (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      reviewText: data['reviewText'] ?? '',
      timestamp:
          data['timestamp'] is Timestamp
              ? data['timestamp'] as Timestamp
              : null,
      clientName: data['clientName'],
    );
  }
}
