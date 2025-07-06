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
    Map data = doc.data() as Map<String, dynamic>;

    // Fetch client name dynamically (this requires an async operation
    // or pre-fetching client data)
    // For simplicity in the model, we might initially just get the ID
    // and fetch the name later in the UI, or store it in the review doc.

    // If you store clientName directly in the review document:
    return RatingReview(
      id: doc.id,
      serviceProviderId: data['serviceProviderId'] ?? '',
      clientId: data['clientId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: data['reviewText'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
      clientName:
          data['clientName'], // Assuming you save clientName with the review
    );
  }
}
