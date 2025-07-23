import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? appointmentId; // Firestore document ID for this appointment
  final String originalBookingId; // Reference to the original booking document
  final String clientId;
  final String clientName;
  final String serviceProviderId;
  final String serviceProviderName;
  final String serviceCategory; // The main category for the appointment
  final DateTime scheduledDate;
  final String scheduledTime;
  final String duration;
  final String
  status; // e.g., 'confirmed', 'in_progress', 'completed', 'cancelled'
  final String? notes;
  final GeoPoint location; // Location where the service will be performed
  final dynamic createdAt;
  final dynamic updatedAt;
  final DateTime? completedAt;

  Appointment({
    this.appointmentId,
    required this.originalBookingId,
    required this.clientId,
    required this.clientName,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.serviceCategory,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.duration,
    required this.status,
    this.notes,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  // Status constants for Appointment
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled =
      'cancelled'; // If an accepted appointment is later cancelled

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Appointment(
      appointmentId: doc.id,
      originalBookingId: data['originalBookingId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      serviceCategory: data['serviceCategory'] ?? '',
      scheduledDate:
          (data['scheduledDate'] is Timestamp)
              ? (data['scheduledDate'] as Timestamp).toDate()
              : DateTime.now(),
      scheduledTime: data['scheduledTime'] ?? '',
      duration: data['duration'] ?? '',
      status: data['status'] ?? Appointment.confirmed,
      notes: data['notes'],
      location:
          data['location'] is GeoPoint
              ? data['location'] as GeoPoint
              : const GeoPoint(0.0, 0.0),
      createdAt:
          (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      completedAt:
          (data['completedAt'] is Timestamp)
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalBookingId': originalBookingId,
      'clientId': clientId,
      'clientName': clientName,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'serviceCategory': serviceCategory,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'duration': duration,
      'status': status,
      'notes': notes,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Appointment copyWith({
    String? appointmentId,
    String? originalBookingId,
    String? clientId,
    String? clientName,
    String? serviceProviderId,
    String? serviceProviderName,
    String? serviceCategory,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? duration,
    String? status,
    String? notes,
    GeoPoint? location,
    dynamic createdAt,
    dynamic updatedAt,
    DateTime? completedAt,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      originalBookingId: originalBookingId ?? this.originalBookingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
