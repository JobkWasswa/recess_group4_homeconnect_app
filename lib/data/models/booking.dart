import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? bookingId;
  final String clientId;
  final String clientName;
  final String serviceProviderId;
  final String serviceProviderName;
  final List<String> categories;
  final String selectedCategory;
  final DateTime bookingDate; 
  final DateTime? scheduledDate; 
  final String? scheduledTime; 
  final String? duration;
  final String status; 
  final String? notes;
  final dynamic createdAt;
  final dynamic updatedAt;
  final GeoPoint location;
  final DateTime? completedAt; 

  Booking({
    this.bookingId,
    required this.clientId,
    required this.clientName,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.categories,
    required this.selectedCategory,
    required this.bookingDate,
    this.scheduledDate, // NEW
    this.scheduledTime, // NEW
    this.duration, // NEW
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
    this.completedAt, // NEW: Optional completion timestamp
  });

  // Status constants - NEW: Added all status options
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completedByProvider = 'completed_by_provider';
  static const String verifiedByHomeowner = 'verified_by_homeowner';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      selectedCategory: data['selectedCategory'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(), // NEW
      scheduledTime: data['scheduledTime'], // NEW
      duration: data['duration'], // NEW
      status: data['status'] ?? pending, // Updated default to use constant
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      completedAt:
          data['completedAt'] !=
                  null // NEW: Handle completion timestamp
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
          scheduledDate != null
              ? Timestamp.fromDate(scheduledDate!)
              : null, // NEW
      'scheduledTime': scheduledTime, // NEW
      'duration': duration, // NEW
      'status': status,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'location': location,
      'completedAt':
          completedAt !=
                  null // NEW: Include completion timestamp
              ? Timestamp.fromDate(completedAt!)
              : null,
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
    DateTime? scheduledDate, // NEW
    String? scheduledTime, // NEW
    String? duration, // NEW
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    DateTime? completedAt, // NEW: Added completion timestamp
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
      scheduledDate: scheduledDate ?? this.scheduledDate, // NEW
      scheduledTime: scheduledTime ?? this.scheduledTime, // NEW
      duration: duration ?? this.duration, // NEW
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      completedAt:
          completedAt ?? this.completedAt, // NEW: Include completion timestamp
    );
  }

  // NEW: Helper method to check if booking is in active state
  bool get isActive {
    return status == pending ||
        status == confirmed ||
        status == inProgress ||
        status == completedByProvider;
  }

  // NEW: Helper method to check if booking is complete
  bool get isCompleted {
    return status == completed;
  }
}
