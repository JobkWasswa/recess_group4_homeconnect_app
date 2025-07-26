import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/models/appointment_modal.dart';

class ServiceProviderRepository {
  final FirebaseFirestore _firestore;

  ServiceProviderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> markJobAsComplete(String bookingId) async {
    final batch = _firestore.batch();

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': Booking.completedByProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final appointmentQuery =
        await _firestore
            .collection('appointments')
            .where('originalBookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

    if (appointmentQuery.docs.isNotEmpty) {
      final appointmentRef = appointmentQuery.docs.first.reference;
      batch.update(appointmentRef, {
        'status': Appointment.completed,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final batch = _firestore.batch();

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus == Booking.confirmed) {
      final bookingDoc = await bookingRef.get();
      if (bookingDoc.exists) {
        final bookingData = Booking.fromFirestore(bookingDoc);

        // Use scheduledDate (including time) and endDateTime - must be non-null
        if (bookingData.scheduledDate != null &&
            bookingData.endDateTime != null) {
          final newAppointment = Appointment(
            originalBookingId: bookingId,
            clientId: bookingData.clientId,
            clientName: bookingData.clientName,
            serviceProviderId: bookingData.serviceProviderId,
            serviceProviderName: bookingData.serviceProviderName,
            serviceCategory: bookingData.selectedCategory,
            scheduledDate: bookingData.scheduledDate!,
            scheduledTime: '', // ← required but unused // date with time
            duration: '', // optional fallback
            startDateTime: bookingData.scheduledDate!, // same as scheduledDate
            endDateTime: bookingData.endDateTime!,
            status: Appointment.confirmed,
            notes: bookingData.notes,
            location: bookingData.location,
            createdAt: null, // Firestore will set this
            updatedAt: null, // Firestore will set this
          );

          batch.set(
            _firestore.collection('appointments').doc(),
            newAppointment.toFirestore(),
          );
        }
      }
    } else if (newStatus == Booking.cancelled ||
        newStatus == Booking.rejectedByProvider) {
      final appointmentQuery =
          await _firestore
              .collection('appointments')
              .where('originalBookingId', isEqualTo: bookingId)
              .limit(1)
              .get();

      if (appointmentQuery.docs.isNotEmpty) {
        final appointmentRef = appointmentQuery.docs.first.reference;
        batch.delete(appointmentRef);
        // Or: batch.update(appointmentRef, {'status': Appointment.cancelled, 'updatedAt': FieldValue.serverTimestamp()});
      }
    } else if (newStatus == Booking.inProgress) {
      final appointmentQuery =
          await _firestore
              .collection('appointments')
              .where('originalBookingId', isEqualTo: bookingId)
              .limit(1)
              .get();

      if (appointmentQuery.docs.isNotEmpty) {
        final appointmentRef = appointmentQuery.docs.first.reference;
        batch.update(appointmentRef, {
          'status': Appointment.inProgress,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // Fetch only pending bookings for new job requests
  Stream<List<Booking>> getPendingBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where('status', isEqualTo: Booking.pending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  // Completed jobs count
  Future<int> getCompletedJobsCount(String providerId) async {
    final snapshot =
        await _firestore
            .collection('bookings')
            .where('serviceProviderId', isEqualTo: providerId)
            .where('status', isEqualTo: Booking.completed)
            .count()
            .get();

    return snapshot.count ?? 0;
  }

  // Stream of appointments for calendar
  Stream<List<Appointment>> getProviderAppointments(String providerId) {
    return _firestore
        .collection('appointments')
        .where('serviceProviderId', isEqualTo: providerId)
        .where(
          'status',
          whereIn: [Appointment.confirmed, Appointment.inProgress],
        )
        .orderBy('scheduledDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Appointment.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get active bookings (pending + confirmed + in progress)
  Stream<List<Booking>> getActiveBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where(
          'status',
          whereIn: [Booking.pending, Booking.confirmed, Booking.inProgress],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }
}
