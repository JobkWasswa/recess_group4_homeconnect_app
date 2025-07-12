import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';

class HomeownerRepository {
  final FirebaseFirestore _firestore;

  HomeownerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
    Future<void> updateBookingStatus(String bookingId, String status) async {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
      // In lib/data/repositories/homeowner_repo.dart
  Future<int> getProviderCompletedJobs(String providerId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where('status', isEqualTo: Booking.completed)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
  // Verify job completion (status: completed_by_provider → completed)
    Future<void> verifyJobCompletion(String bookingId, String providerId) async {
      final batch = _firestore.batch();

      // 1. Update booking status
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {
        'status': Booking.completed,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    // 2. Increment provider's completed jobs count
    final providerRef = _firestore.collection('service_providers').doc(providerId);
    batch.update(providerRef, {
      'completedJobs': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Get bookings needing verification (completed_by_provider status)
  Stream<List<Booking>> getBookingsNeedingVerification(String homeownerId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: homeownerId)
        .where('status', isEqualTo: Booking.completedByProvider)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }
}