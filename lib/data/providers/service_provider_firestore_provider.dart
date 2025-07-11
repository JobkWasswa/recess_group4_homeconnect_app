// File: lib/data/providers/service_provider_firestore_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:geolocator/geolocator.dart'; // For distance calculation

class ServiceProviderFirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen for new job requests for a specific service provider
  Stream<List<Booking>> getNewJobRequests(String serviceProviderId) {
    return _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: serviceProviderId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  // Update the status of a booking (accept or reject)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  // Helper function to calculate distance (if you don't have one already)
  // This assumes clientLocation and serviceProviderLocation are GeoPoint
  double calculateDistance(
    GeoPoint clientLocation,
    GeoPoint serviceProviderLocation,
  ) {
    return Geolocator.distanceBetween(
          clientLocation.latitude,
          clientLocation.longitude,
          serviceProviderLocation.latitude,
          serviceProviderLocation.longitude,
        ) /
        1000; // Convert to kilometers
  }

  // Fetch a single booking by ID (useful after accepting/rejecting)
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (doc.exists) {
      return Booking.fromFirestore(doc);
    }
    return null;
  }
}
