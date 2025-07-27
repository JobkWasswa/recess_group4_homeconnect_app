import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart.split(RegExp(r'[._]'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

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
      return userId;
    } catch (e) {
      return userId;
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 140, 49, 214),
                Color.fromARGB(255, 221, 30, 148),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Conversations',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
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
                style: GoogleFonts.nunito(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
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
                    style: GoogleFonts.nunito(
                      color: Colors.grey[600],
                      fontSize: 16,
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
                    title: Text(
                      'Unknown participant',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(lastMessage, style: GoogleFonts.nunito()),
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
                    shadowColor: Colors.purple.withOpacity(0.2),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.purple[300],
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      trailing:
                          lastTimestamp != null
                              ? Text(
                                _formatTimestamp(lastTimestamp),
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.grey[500],
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
                      hoverColor: Colors.purple.withOpacity(0.08),
                      splashColor: Colors.purple.withOpacity(0.15),
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
