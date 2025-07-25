import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/repositories/homeowner_repo.dart';

class GetBookingsNeedingVerificationUseCase {
  final HomeownerRepository _repository;

  GetBookingsNeedingVerificationUseCase(this._repository);

  Stream<List<Booking>> execute(String homeownerId) {
    return _repository.getBookingsNeedingVerification(homeownerId);
  }
}

class VerifyJobCompletionUseCase {
  final HomeownerRepository _repository;

  VerifyJobCompletionUseCase(this._repository);

  Future<void> execute(String bookingId, String providerId) async {
    // Business rule: Verify only if booking is in completed_by_provider state
    await _repository.verifyJobCompletion(bookingId, providerId);
  }
}

class CancelBookingUseCase {
  final HomeownerRepository _repository;

  CancelBookingUseCase(this._repository);

  Future<void> execute(String bookingId) async {
    await _repository.updateBookingStatus(
      bookingId,
      Booking.cancelled,
    );
  }
}

class GetServiceProviderDetailsUseCase {
  final HomeownerRepository _repository;

  GetServiceProviderDetailsUseCase(this._repository);

  Future<Map<String, dynamic>> execute(String providerId) async {
    final completedJobs = await _repository.getProviderCompletedJobs(providerId);
    return {
      'completedJobs': completedJobs,
      // Can add more provider details here
    };
  }
}