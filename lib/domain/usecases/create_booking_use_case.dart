// File: homeconnect/domain/usecases/create_booking_use_case.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository _repository;

  CreateBookingUseCase(this._repository);

  Future<Booking> execute({
    required String clientId,
    required String clientName,
    required String serviceProviderId,
    required String serviceProviderName,
    required List<String> categories,
    required String selectedCategory,
    required DateTime bookingDate,
    required GeoPoint location,
    required bool isFullDay, // ✅ ADD THIS LINE
    String? notes,
  }) async {
    return await _repository.createBooking(
      clientId: clientId,
      clientName: clientName,
      serviceProviderId: serviceProviderId,
      serviceProviderName: serviceProviderName,
      categories: categories,
      selectedCategory: selectedCategory,
      bookingDate: bookingDate,
      location: location,
      notes: notes,
      isFullDay: isFullDay, // ✅ include this field
    );
  }
}
