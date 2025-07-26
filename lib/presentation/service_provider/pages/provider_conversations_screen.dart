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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Your Conversations'),
        centerTitle: true,
        elevation: 6,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No conversations found.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: const Text('Unknown participant'),
                    subtitle: Text(lastMessage),
                  ),
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

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.purple.withOpacity(0.3),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.purple[300],
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.4,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing:
                          lastTimestamp != null
                              ? Text(
                                _formatTimestamp(lastTimestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                              : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
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
                      hoverColor: Colors.purple.withOpacity(0.1),
                      splashColor: Colors.purpleAccent.withOpacity(0.2),
                    ),
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
