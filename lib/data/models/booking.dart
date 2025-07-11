// File: lib/data/models/booking.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? bookingId;
  final String clientId;
  final String clientName;
  final String? clientEmail; // ✅ New field
  final GeoPoint? clientLocation; // ✅ New field
  final String serviceProviderId;
  final String serviceProviderName;
  final List<String> categories;
  final DateTime bookingDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    this.bookingId,
    required this.clientId,
    required this.clientName,
    this.clientEmail, // Initialize new field
    this.clientLocation, // Initialize new field
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.categories,
    required this.bookingDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'], // Fetch new field
      clientLocation: data['clientLocation'] as GeoPoint?, // Fetch new field
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail, // Add new field
      'clientLocation': clientLocation, // Add new field
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

  Booking copyWith({
    String? bookingId,
    String? clientId,
    String? clientName,
    String? clientEmail, // Add to copyWith
    GeoPoint? clientLocation, // Add to copyWith
    String? serviceProviderId,
    String? serviceProviderName,
    List<String>? categories,
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
      clientEmail: clientEmail ?? this.clientEmail, // Update copyWith
      clientLocation: clientLocation ?? this.clientLocation, // Update copyWith
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
