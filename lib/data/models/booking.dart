import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? bookingId;
  final String clientId;
  final String clientName;
  final String serviceProviderId;
  final String serviceProviderName;
  final List<String> categories;
  final String selectedCategory; // ✅ NEW
  final DateTime bookingDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeoPoint location;

  Booking({
    this.bookingId,
    required this.clientId,
    required this.clientName,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.categories,
    required this.selectedCategory, // ✅ NEW
    required this.bookingDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      selectedCategory: data['selectedCategory'] ?? '', // ✅ NEW
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'categories': categories,
      'selectedCategory': selectedCategory, // ✅ NEW
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
    };
  }

  Booking copyWith({
    String? bookingId,
    String? clientId,
    String? clientName,
    String? serviceProviderId,
    String? serviceProviderName,
    List<String>? categories,
    String? selectedCategory, // ✅ NEW
    DateTime? bookingDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory, // ✅ NEW
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
    );
  }
}
