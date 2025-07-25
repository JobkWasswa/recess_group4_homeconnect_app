import 'package:homeconnect/data/models/booking.dart';
import 'package:homeconnect/data/repositories/service_provider_repo.dart';

class GetActiveBookingsUseCase {
  final ServiceProviderRepository _repository;

  GetActiveBookingsUseCase(this._repository);

  Stream<List<Booking>> execute(String providerId) {
    return _repository.getActiveBookings(providerId);
  }
}

class MarkJobCompleteUseCase {
  final ServiceProviderRepository _repository;

  MarkJobCompleteUseCase(this._repository);

  Future<void> execute(String bookingId) async {
    // Business rule: Ensure booking exists before marking complete
    await _repository.markJobAsComplete(bookingId);
  }
}

class GetProviderStatsUseCase {
  final ServiceProviderRepository _repository;

  GetProviderStatsUseCase(this._repository);

  Future<Map<String, dynamic>> execute(String providerId) async {
    final completedCount = await _repository.getCompletedJobsCount(providerId);
    return {
      'completedJobs': completedCount,
      // Can add more stats here later
    };
  }
}

class StartJobUseCase {
  final ServiceProviderRepository _repository;

  StartJobUseCase(this._repository);

  Future<void> execute(String bookingId) async {
    await _repository.updateBookingStatus(
      bookingId,
      Booking.inProgress,
    );
  }
}