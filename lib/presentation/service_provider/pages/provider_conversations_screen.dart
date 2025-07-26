import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:homeconnect/presentation/service_provider/widgets/chat_screen.dart';

class ProviderConversationsScreen extends StatefulWidget {
  const ProviderConversationsScreen({super.key});

  @override
  State<ProviderConversationsScreen> createState() =>
      _ProviderConversationsScreenState();
}

class _ProviderConversationsScreenState
    extends State<ProviderConversationsScreen> {
  final String currentProviderId = FirebaseAuth.instance.currentUser!.uid;

  // Helper to convert email to display name
  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart.split(RegExp(r'[._]'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Fetch user display name by their userId
  Future<String> _fetchUserName(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('email')) {
          final email = data['email'] as String;
          return _nameFromEmail(email);
        }
      }
      return userId; // fallback: show UID if no email found
    } catch (e) {
      return userId; // fallback on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsStream =
        FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentProviderId)
            .orderBy('lastTimestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Conversations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No conversations found.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>? ?? [];

              final otherUserId = participants.firstWhere(
                (id) => id != currentProviderId,
                orElse: () => null,
              );

              final lastMessage = data['lastMessage'] ?? '';
              final Timestamp? ts = data['lastTimestamp'] as Timestamp?;
              final lastTimestamp = ts?.toDate();

              if (otherUserId == null) {
                return ListTile(
                  title: const Text('Unknown participant'),
                  subtitle: Text(lastMessage),
                );
              }

              return FutureBuilder<String>(
                future: _fetchUserName(otherUserId),
                builder: (context, snapshot) {
                  String displayName = otherUserId;
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    displayName = snapshot.data!;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        lastTimestamp != null
                            ? Text(
                              _formatTimestamp(lastTimestamp),
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
                              (_) => ChatScreen(
                                otherUserId: otherUserId,
                                otherUserName: displayName,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays > 1) {
      return '${dt.month}/${dt.day}/${dt.year}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
