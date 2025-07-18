import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/models/appointment_modal.dart'; // NEW: Import Appointment model

class ServiceProviderRepository {
  final FirebaseFirestore _firestore;

  ServiceProviderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Mark job as complete (status: in_progress → completed_by_provider)
  // This will now also update the corresponding appointment
  Future<void> markJobAsComplete(String bookingId) async {
    final batch = _firestore.batch();

    // Update the original booking status
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': Booking.completedByProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update the corresponding appointment status
    // Find the appointment linked to this bookingId
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

  // Generic method to update booking status (and corresponding appointment status)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final batch = _firestore.batch();

    // Update the original booking status
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Handle appointment creation/update based on newStatus
    if (newStatus == Booking.confirmed) {
      // Fetch the booking details to create an appointment
      final bookingDoc = await bookingRef.get();
      if (bookingDoc.exists) {
        final bookingData = Booking.fromFirestore(bookingDoc);
        if (bookingData.scheduledDate != null &&
            bookingData.scheduledTime != null &&
            bookingData.duration != null) {
          final newAppointment = Appointment(
            originalBookingId: bookingId,
            clientId: bookingData.clientId,
            clientName: bookingData.clientName,
            serviceProviderId: bookingData.serviceProviderId,
            serviceProviderName: bookingData.serviceProviderName,
            serviceCategory:
                bookingData
                    .selectedCategory, // Use selectedCategory for appointment
            scheduledDate: bookingData.scheduledDate!,
            scheduledTime: bookingData.scheduledTime!,
            duration: bookingData.duration!,
            status: Appointment.confirmed, // Initial status for appointment
            notes: bookingData.notes,
            location: bookingData.location,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          );
          batch.set(
            _firestore.collection('appointments').doc(),
            newAppointment.toFirestore(),
          );
        } else {
          print(
            'Warning: Cannot create appointment. Missing scheduledDate, scheduledTime, or duration for booking $bookingId',
          );
        }
      }
    } else if (newStatus == Booking.cancelled ||
        newStatus == Booking.rejectedByProvider) {
      // If booking is cancelled/rejected, find and delete/update the corresponding appointment
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

  // Get active bookings for provider dashboard (still from bookings collection for job requests)
  // This method will now only fetch 'pending' bookings for the dashboard's "New Job Requests" section.
  // Active/Confirmed jobs will be handled by the calendar screen directly from 'appointments'.
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

  // Get completed jobs count for stats (still from bookings collection as it's the source of truth for all jobs)
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

  // NEW: Get stream of appointments for the calendar screen
  Stream<List<Appointment>> getProviderAppointments(String providerId) {
    return _firestore
        .collection('appointments')
        .where('serviceProviderId', isEqualTo: providerId)
        .where(
          'status',
          whereIn: [Appointment.confirmed, Appointment.inProgress],
        ) // Only confirmed/in-progress
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Appointment.fromFirestore(doc))
                  .toList(),
        );
  }
}
