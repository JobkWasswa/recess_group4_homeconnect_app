import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart'; // Make sure this path is correct

class ServiceProviderFirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Booking>> fetchPendingBookings(String serviceProviderId) async {
    try {
      final QuerySnapshot result =
          await _firestore
              .collection('bookings')
              .where('serviceProviderId', isEqualTo: serviceProviderId)
              .where('status', isEqualTo: 'pending')
              .orderBy(
                'createdAt',
                descending: true,
              ) // Order by latest requests
              .get();

      return result.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching pending bookings: $e');
      rethrow; // Re-throw to be handled by the UI
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }
}
