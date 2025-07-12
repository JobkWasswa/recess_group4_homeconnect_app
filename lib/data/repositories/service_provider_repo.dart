import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';

class ServiceProviderRepository {
  final FirebaseFirestore _firestore;

  ServiceProviderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Mark job as complete (status: in_progress → completed_by_provider)
  Future<void> markJobAsComplete(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': Booking.completedByProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get active bookings for provider dashboard
  Stream<List<Booking>> getActiveBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where('status', whereIn: [
          Booking.pending,
          Booking.confirmed,
          Booking.inProgress,
          Booking.completedByProvider,
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  // Optional: Get completed jobs count for stats
 Future<int> getCompletedJobsCount(String providerId) async {
  final snapshot = await _firestore
      .collection('bookings')
      .where('serviceProviderId', isEqualTo: providerId)
      .where('status', isEqualTo: Booking.completed)
      .count()
      .get();
      
  return snapshot.count ?? 0; // Provide default value if null

  }
}