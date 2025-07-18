import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? bookingId; // Firestore document ID for this booking
  final String clientId;
  final String clientName;
  final String serviceProviderId;
  final String serviceProviderName;
  final List<String> categories;
  final String selectedCategory;
  final DateTime bookingDate; // Original booking creation date
  final DateTime? scheduledDate; // Scheduled date for the service
  final String? scheduledTime; // Scheduled time for the service
  final String? duration; // Duration of the service
  final String status; // Updated with new status flow
  final String? notes;
  final dynamic createdAt;
  final dynamic updatedAt;
  final GeoPoint location;
  final DateTime? completedAt; // Added completion timestamp

  Booking({
    this.bookingId, // Make sure this is part of the constructor
    required this.clientId,
    required this.clientName,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.categories,
    required this.selectedCategory,
    required this.bookingDate,
    this.scheduledDate,
    this.scheduledTime,
    this.duration,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
    this.completedAt,
  });

  // Status constants
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completedByProvider = 'completed_by_provider';
  static const String verifiedByHomeowner = 'verified_by_homeowner';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String rejectedByProvider =
      'rejected_by_provider'; // Added this for completeness

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id, // Assign the document ID here
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      selectedCategory: data['selectedCategory'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      scheduledTime: data['scheduledTime'],
      duration: data['duration'],
      status: data['status'] ?? pending,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'categories': categories,
      'selectedCategory': selectedCategory,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTime': scheduledTime,
      'duration': duration,
      'status': status,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'location': location,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Booking copyWith({
    String? bookingId,
    String? clientId,
    String? clientName,
    String? serviceProviderId,
    String? serviceProviderName,
    List<String>? categories,
    String? selectedCategory,
    DateTime? bookingDate,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? duration,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    DateTime? completedAt,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      bookingDate: bookingDate ?? this.bookingDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isActive {
    return status == pending ||
        status == confirmed ||
        status == inProgress ||
        status == completedByProvider;
  }

  bool get isCompleted {
    return status == completed;
  }
}

