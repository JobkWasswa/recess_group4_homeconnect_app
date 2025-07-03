import 'package:flutter/material.dart';
import 'package:homeconnect/data/models/booking.dart'; // Assuming JobRequest is defined here

// IMPORTANT: These abstract classes must ONLY be defined in this file.
abstract class CreateJobRequestUseCase {
  Future<void> execute(JobRequest request);
}

abstract class GetHomeownerJobRequestsUseCase {
  Stream<List<JobRequest>> execute(String homeownerId);
}

abstract class GetServiceProviderJobRequestsUseCase {
  Stream<List<JobRequest>> execute(String serviceProviderId);
}

abstract class GetPendingJobRequestsUseCase {
  Stream<List<JobRequest>> execute();
}

abstract class AcceptJobRequestUseCase {
  Future<void> execute(
    String jobId,
    String serviceProviderId,
    String serviceProviderName,
  );
}

abstract class RejectJobRequestUseCase {
  Future<void> execute(String jobId, String rejectionReason);
}

abstract class CompleteJobRequestUseCase {
  Future<void> execute(String jobId, double finalPrice);
}

class JobNotifier extends ChangeNotifier {
  final CreateJobRequestUseCase createJobRequestUseCase;
  final GetHomeownerJobRequestsUseCase getHomeownerJobRequestsUseCase;
  final GetServiceProviderJobRequestsUseCase
  getServiceProviderJobRequestsUseCase;
  final GetPendingJobRequestsUseCase getPendingJobRequestsUseCase;
  final AcceptJobRequestUseCase acceptJobRequestUseCase;
  final RejectJobRequestUseCase rejectJobRequestUseCase;
  final CompleteJobRequestUseCase completeJobRequestUseCase;

  JobNotifier({
    required this.createJobRequestUseCase,
    required this.getHomeownerJobRequestsUseCase,
    required this.getServiceProviderJobRequestsUseCase,
    required this.getPendingJobRequestsUseCase,
    required this.acceptJobRequestUseCase,
    required this.rejectJobRequestUseCase,
    required this.completeJobRequestUseCase,
  });

  Future<void> createJobRequest(JobRequest request) async {
    try {
      await createJobRequestUseCase.execute(request);
      notifyListeners();
    } catch (e) {
      print('Error creating job request: $e');
    }
  }

  Stream<List<JobRequest>> getPendingJobs() {
    return getPendingJobRequestsUseCase.execute();
  }

  Stream<List<JobRequest>> getHomeownerJobs(String homeownerId) {
    return getHomeownerJobRequestsUseCase.execute(homeownerId);
  }

  Stream<List<JobRequest>> getServiceProviderJobs(String serviceProviderId) {
    return getServiceProviderJobRequestsUseCase.execute(serviceProviderId);
  }

  Future<void> acceptJobRequest(
    String jobId,
    String serviceProviderId,
    String serviceProviderName,
  ) async {
    try {
      await acceptJobRequestUseCase.execute(
        jobId,
        serviceProviderId,
        serviceProviderName,
      );
      notifyListeners();
    } catch (e) {
      print('Error accepting job request: $e');
    }
  }

  Future<void> rejectJobRequest(String jobId, String rejectionReason) async {
    try {
      await rejectJobRequestUseCase.execute(jobId, rejectionReason);
      notifyListeners();
    } catch (e) {
      print('Error rejecting job request: $e');
    }
  }

  Future<void> completeJobRequest(String jobId, double finalPrice) async {
    try {
      await completeJobRequestUseCase.execute(jobId, finalPrice);
      notifyListeners();
    } catch (e) {
      print('Error completing job request: $e');
    }
  }
}
