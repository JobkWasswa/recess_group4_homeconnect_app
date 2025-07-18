import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/models/appointment_modal.dart'; // NEW: Import Appointment model

class HomeownerRepository {
  final FirebaseFirestore _firestore;

  HomeownerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Method to update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    final batch = _firestore.batch();

    // Update the original booking status
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If status is cancelled, also update/delete the appointment
    if (status == Booking.cancelled) {
      final appointmentQuery =
          await _firestore
              .collection('appointments')
              .where('originalBookingId', isEqualTo: bookingId)
              .limit(1)
              .get();

      if (appointmentQuery.docs.isNotEmpty) {
        final appointmentRef = appointmentQuery.docs.first.reference;
        // Option 1: Delete the appointment
        batch.delete(appointmentRef);
        // Option 2: Mark appointment as cancelled (if you want a history)
        // batch.update(appointmentRef, {'status': Appointment.cancelled, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }

    await batch.commit();
  }

  // Get completed jobs count for a specific provider
  Future<int> getProviderCompletedJobs(String providerId) async {
    final snapshot =
        await _firestore
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
    final providerRef = _firestore
        .collection('service_providers')
        .doc(providerId);
    batch.update(providerRef, {'completedJobs': FieldValue.increment(1)});

    // 3. Update the corresponding appointment status
    final appointmentQuery =
        await _firestore
            .collection('appointments')
            .where('originalBookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

    if (appointmentQuery.docs.isNotEmpty) {
      final appointmentRef = appointmentQuery.docs.first.reference;
      batch.update(appointmentRef, {
        'status': Appointment.completed, // Mark appointment as completed
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Get bookings needing verification (completed_by_provider status)
  Stream<List<Booking>> getBookingsNeedingVerification(String homeownerId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: homeownerId)
        .where('status', isEqualTo: Booking.completedByProvider)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }
}
