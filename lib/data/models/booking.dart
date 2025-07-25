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
  final DateTime? endDateTime; // Add this line
  final String? scheduledTime; // Scheduled time for the service
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
    this.endDateTime, // Add this in the constructor list
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
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Booking(
      bookingId: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories:
          (data['categories'] is List)
              ? List<String>.from(data['categories'])
              : <String>[],
      selectedCategory: data['selectedCategory'] ?? '',
      bookingDate:
          (data['bookingDate'] is Timestamp)
              ? (data['bookingDate'] as Timestamp).toDate()
              : DateTime.now(),
      scheduledDate:
          (data['scheduledDate'] is Timestamp)
              ? (data['scheduledDate'] as Timestamp).toDate()
              : null,
      endDateTime:
          (data['endDateTime'] is Timestamp)
              ? (data['endDateTime'] as Timestamp).toDate()
              : null,
      scheduledTime: data['scheduledTime'],
      status: data['status'] ?? Booking.pending,
      notes: data['notes'],
      createdAt:
          (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      location:
          (data['location'] is GeoPoint)
              ? data['location'] as GeoPoint
              : const GeoPoint(0, 0),
      completedAt:
          (data['completedAt'] is Timestamp)
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
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
      'endDateTime':
          endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
      'scheduledTime': scheduledTime,
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
    DateTime? endDateTime,
    String? scheduledTime,
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
      endDateTime: endDateTime ?? this.endDateTime, // <--- set it
      scheduledTime: scheduledTime ?? this.scheduledTime,
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
