// File: homeconnect/presentation/chat/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/data/models/chat_models.dart';
import 'package:homeconnect/presentation/chat/chat_screen.dart'; // Import the ChatScreen
import 'package:intl/intl.dart'; // For date formatting

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Chats'),
          backgroundColor: const Color(0xFF9333EA),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view your chats.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        backgroundColor: const Color(0xFF9333EA), // Purple
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chats')
                .where('participants', arrayContains: _currentUser!.uid)
                .where('isActive', isEqualTo: true) // Only show active chats
                .orderBy('lastMessageTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading chats: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats at the moment.'));
          }

          final chatRooms =
              snapshot.data!.docs
                  .map((doc) => ChatRoom.fromFirestore(doc))
                  .toList();

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              // Determine the other participant's ID and name
              final String otherParticipantId =
                  chatRoom.homeownerId == _currentUser!.uid
                      ? chatRoom.serviceProviderId
                      : chatRoom.homeownerId;

              // You'll need to fetch the other participant's name.
              // For simplicity, I'll use a placeholder or their ID for now.
              // In a real app, you'd fetch user/provider details from their respective collections.
              String otherParticipantName = 'Loading Name...'; // Placeholder

              // Fetch the other participant's name (Homeowner or Service Provider)
              // This is a simplified approach. For a robust solution, consider a BLoC/Provider
              // or a dedicated service to fetch user details.
              // For now, let's just use their ID for the name if we can't fetch it directly.
              // A more complete solution would involve a FutureBuilder or pre-fetching names.
              // For the sake of getting the chat working, we'll use a simple approach.
              // You might need to adjust this based on how you store user names.
              // Example: If otherParticipantId is a homeowner, fetch from 'users' collection.
              // If it's a service provider, fetch from 'service_providers' collection.

              // For demonstration, let's assume we can fetch the name.
              // A real implementation would involve a more robust way to get the name
              // (e.g., from a cached list of users, or a dedicated fetch).
              // For this example, we'll just show the ID if name isn't readily available.
              // You can expand this with a FutureBuilder for the name if needed.
              // For now, let's use a simple placeholder.
              otherParticipantName = otherParticipantId; // Fallback to ID

              // You would ideally have a way to fetch the actual name here.
              // For instance, if you have a User model for homeowners and ServiceProviderModel for providers,
              // you'd query the respective collection.
              // Example (conceptual):
              // _firestore.collection('users').doc(otherParticipantId).get().then((doc) {
              //   if (doc.exists) otherParticipantName = doc.data()!['fullName'] ?? doc.data()!['name'];
              // });
              // OR
              // _firestore.collection('service_providers').doc(otherParticipantId).get().then((doc) {
              //   if (doc.exists) otherParticipantName = doc.data()!['fullName'] ?? doc.data()!['name'];
              // });

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Icon(Icons.person, color: Colors.purple[700]),
                  ),
                  title: Text(
                    'Chat with $otherParticipantName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chatRoom.lastMessage ?? 'No messages yet.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      chatRoom.lastMessageTimestamp != null
                          ? Text(
                            DateFormat(
                              'MMM d, h:mm a',
                            ).format(chatRoom.lastMessageTimestamp!.toDate()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                          : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatScreen(
                              chatId: chatRoom.id,
                              otherParticipantId: otherParticipantId,
                              otherParticipantName:
                                  otherParticipantName, // Pass the name
                              bookingId: chatRoom.bookingId,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
