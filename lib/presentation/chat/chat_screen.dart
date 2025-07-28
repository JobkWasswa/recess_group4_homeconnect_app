// File: homeconnect/presentation/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homeconnect/data/models/chat_models.dart'; // Import ChatMessage model
import 'package:intl/intl.dart'; // For formatting timestamps

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherParticipantId;
  final String otherParticipantName; // Name of the other person in chat
  final String bookingId; // The associated booking ID

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.bookingId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _currentUser;
  bool _isChatActive = true; // State to track if chat is active

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      // Handle case where user is not logged in, e.g., navigate to login
      print("User not logged in to access chat.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to chat.')),
        );
        Navigator.of(context).pop(); // Go back if not logged in
      });
    } else {
      _listenToChatStatus(); // Listen for chat activation/deactivation
    }
  }

  void _listenToChatStatus() {
    _firestore.collection('chats').doc(widget.chatId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final chatData = snapshot.data();
        setState(() {
          _isChatActive = chatData?['isActive'] as bool? ?? true;
        });
        if (!_isChatActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This chat has been deactivated as the job is completed/cancelled.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Chat room might have been deleted or doesn't exist
        setState(() {
          _isChatActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This chat room no longer exists.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isChatActive) {
      return; // Don't send empty messages or if chat is inactive
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to send messages.'),
        ),
      );
      return;
    }

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final chatMessagesRef = _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

      final newMessage = ChatMessage(
        id: chatMessagesRef.doc().id, // Firestore will generate ID
        senderId: _currentUser!.uid,
        text: messageText,
        timestamp:
            Timestamp.now(), // Will be overwritten by serverTimestamp in toFirestore
      );

      await chatMessagesRef.add(newMessage.toFirestore());

      // Update lastMessage and lastMessageTimestamp in the chat room document
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherParticipantName}'),
        backgroundColor: const Color(0xFF9333EA), // Purple
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy(
                        'timestamp',
                        descending: true,
                      ) // Show latest messages at bottom
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Say hello! No messages yet.'),
                  );
                }

                final messages =
                    snapshot.data!.docs
                        .map((doc) => ChatMessage.fromFirestore(doc))
                        .toList();

                return ListView.builder(
                  reverse: true, // Display messages from bottom up
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _currentUser?.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft:
                                isMe
                                    ? const Radius.circular(15)
                                    : const Radius.circular(0),
                            bottomRight:
                                isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(message.timestamp.toDate()),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (!_isChatActive)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: const Text(
                'Chat is deactivated for this job.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText:
                          _isChatActive
                              ? 'Enter message...'
                              : 'Chat is deactivated',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                    ),
                    enabled: _isChatActive, // Disable input if chat is inactive
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor:
                      _isChatActive ? const Color(0xFF9333EA) : Colors.grey,
                  elevation: 0,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
