// File: homeconnect/data/repositories/booking_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new booking in Firestore after performing necessary checks.
  /// Throws an exception if the booking date is in the past, or if
  /// a similar active booking already exists for the same client and service provider.
  Future<Booking> createBooking({
    required String clientId,
    required String clientName,
    required String serviceProviderId,
    required String serviceProviderName,
    required List<String> categories,
    required String selectedCategory,
    required DateTime bookingDate,
    required GeoPoint location,
    String? notes,
  }) async {
    // 1. Basic validation: Ensure booking date is in the future
    if (bookingDate.isBefore(DateTime.now())) {
      throw Exception('Booking date cannot be in the past.');
    }

    // 2. Check for existing active bookings for the same client and service provider
    //    An active booking is defined by the 'isActive' getter in the Booking model.
    final QuerySnapshot existingBookings =
        await _firestore
            .collection('bookings')
            .where('clientId', isEqualTo: clientId)
            .where('serviceProviderId', isEqualTo: serviceProviderId)
            .where(
              'status',
              whereIn: [
                Booking.pending,
                Booking.confirmed,
                Booking.inProgress,
                Booking.completedByProvider,
              ],
            )
            .get();

    if (existingBookings.docs.isNotEmpty) {
      // You might want to refine this check, e.g., allow multiple bookings for different dates/categories
      // For simplicity, this currently prevents any active booking between the same client and provider.
      throw Exception(
        'An active booking already exists with this service provider.',
      );
    }

    // 3. Create the new booking object
    final newBooking = Booking(
      clientId: clientId,
      clientName: clientName,
      serviceProviderId: serviceProviderId,
      serviceProviderName: serviceProviderName,
      categories: categories,
      selectedCategory: selectedCategory,
      bookingDate: bookingDate,
      status: Booking.pending, // Default status for new bookings
      notes: notes,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      location: location,
    );

    // 4. Add the booking to Firestore
    final DocumentReference docRef = await _firestore
        .collection('bookings')
        .add(newBooking.toFirestore());

    // 5. Fetch the newly created booking to get its ID and accurate server timestamps
    final DocumentSnapshot createdDoc = await docRef.get();
    return Booking.fromFirestore(createdDoc);
  }
}
