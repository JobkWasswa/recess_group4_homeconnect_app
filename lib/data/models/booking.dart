import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String?
  bookingId; // Made nullable as Firestore generates this on first add
  final String clientId;
  final String clientName;
  final String serviceProviderId;
  final String serviceProviderName;
  final String categories;
  final DateTime bookingDate;
  final String status;
  final String? notes; // Optional field
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    this.bookingId, // Nullable for new bookings before they get an ID from Firestore
    required this.clientId,
    required this.clientName,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.categories,
    required this.bookingDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Booking object from a Firestore DocumentSnapshot
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id, // The document ID is the bookingId
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories: data['categories'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert a Booking object to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'categories': categories,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Optional: Add a copyWith method for immutability if you need to create
  // modified copies of existing bookings (e.g., to change status)
  Booking copyWith({
    String? bookingId,
    String? clientId,
    String? clientName,
    String? serviceProviderId,
    String? serviceProviderName,
    String? categories,
    DateTime? bookingDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      categories: categories ?? this.categories,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
