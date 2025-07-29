// File: homeconnect/data/models/chat_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between a homeowner and a service provider for a specific booking.
class ChatRoom {
  final String id; // Document ID of the chat room
  final String bookingId; // The ID of the associated booking
  final String homeownerId;
  final String serviceProviderId;
  final String? lastMessage;
  final Timestamp? lastMessageTimestamp;
  final bool
  isActive; // True if chat is currently active, false if deactivated (job completed/cancelled)
  final List<String> participants; // List of UIDs of participants

  ChatRoom({
    required this.id,
    required this.bookingId,
    required this.homeownerId,
    required this.serviceProviderId,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.isActive,
    required this.participants, // Ensure this is passed to the constructor
  });

  /// Factory constructor to create a ChatRoom from a Firestore DocumentSnapshot.
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      homeownerId: data['homeownerId'] as String,
      serviceProviderId: data['serviceProviderId'] as String,
      lastMessage: data['lastMessage'] as String?,
      lastMessageTimestamp: data['lastMessageTimestamp'] as Timestamp?,
      isActive:
          data['isActive'] as bool? ?? true, // Default to true if not specified
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  /// Convert ChatRoom object to a Map for Firestore.
  @override // Added @override for clarity, though not strictly necessary
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'homeownerId': homeownerId,
      'serviceProviderId': serviceProviderId,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'isActive': isActive,
      'participants':
          participants, // <--- CRITICAL FIX: Include participants in the map
      'createdAt': FieldValue.serverTimestamp(), // Add createdAt for new chats
      'updatedAt': FieldValue.serverTimestamp(), // Add updatedAt for new chats
    };
  }
}

/// Represents a single message within a chat room.
class ChatMessage {
  final String id; // Document ID of the message
  final String senderId;
  final String text;
  final Timestamp timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  /// Factory constructor for creating a ChatMessage from a Firestore DocumentSnapshot.
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  /// Convert ChatMessage object to a Map for Firestore.
  @override // Added @override for clarity
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp':
          FieldValue.serverTimestamp(), // Use server timestamp for message creation
    };
  }
}
