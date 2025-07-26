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

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 Current provider UID: $currentProviderId');

    // Query conversations where current provider is a participant
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
            debugPrint('⏳ Waiting for conversation stream...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Conversation stream error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint('⚠️ No conversation data found.');
            return const Center(child: Text('No conversations found.'));
          }

          final docs = snapshot.data!.docs;
          debugPrint('📦 Total conversations found: ${docs.length}');

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;

              debugPrint('🔍 Conversation ${index + 1} raw data: $data');

              List participants = data['participants'] ?? [];

              final otherUserId = participants.firstWhere(
                (id) => id != currentProviderId,
                orElse: () {
                  debugPrint(
                    '⚠️ Could not find other user in participants list.',
                  );
                  return null;
                },
              );

              final lastMessage = data['lastMessage'] ?? '';
              final Timestamp? ts = data['lastTimestamp'] as Timestamp?;
              final lastTimestamp = ts?.toDate();

              final otherUserName =
                  data['participantsNames'] != null
                      ? (data['participantsNames']
                              as Map<String, dynamic>)[otherUserId] ??
                          otherUserId
                      : otherUserId ?? 'Unknown';

              debugPrint(
                '✅ Chat with $otherUserId - Display name: $otherUserName',
              );

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserName[0].toUpperCase()),
                ),
                title: Text(otherUserName),
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
                  if (otherUserId != null) {
                    debugPrint('➡️ Navigating to chat with $otherUserId');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatScreen(
                              otherUserId: otherUserId,
                              otherUserName: otherUserName,
                            ),
                      ),
                    );
                  } else {
                    debugPrint('❗ Cannot navigate: otherUserId is null');
                  }
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
