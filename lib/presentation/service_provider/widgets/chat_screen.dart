import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class ChatScreen extends StatefulWidget {
  final String otherUserId; // e.g. homeownerId or providerId
  final String otherUserName; // raw email or fallback name

  const ChatScreen({
    required this.otherUserId,
    required this.otherUserName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late final String conversationId;
  String _displayName = ''; // Will hold the fetched display name

  @override
  void initState() {
    super.initState();
    conversationId = _generateConversationId(currentUserId, widget.otherUserId);
    _loadDisplayName(); // Load display name on init
  }

  String _generateConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join("_");
  }

  // Helper to convert email to name
  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart.split(RegExp(r'[._]'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Fetch display name from Firestore users collection by userId
  Future<void> _loadDisplayName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .get();

      if (doc.exists) {
        final email = doc['email'] as String? ?? '';
        setState(() {
          _displayName =
              email.isNotEmpty ? _nameFromEmail(email) : widget.otherUserName;
        });
      } else {
        setState(() {
          _displayName = widget.otherUserName;
        });
      }
    } catch (e) {
      setState(() {
        _displayName = widget.otherUserName;
      });
    }
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final senderName = user.displayName ?? user.email ?? 'Unknown';

    final messageData = {
      'senderId': currentUserId,
      'senderName': senderName,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    final messageRef =
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc();

    await messageRef.set(messageData);

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .set({
          'participants': [currentUserId, widget.otherUserId],
          'lastMessage': text.trim(),
          'lastTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    _controller.clear();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      // Show time only if today
      return DateFormat.jm().format(date);
    } else {
      return DateFormat.yMd().add_jm().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageStream =
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots();

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        124,
        124,
        124,
      ), // Dark gray background for contrast
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 4,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8A80), // light pink
                  Color(0xFF6A11CB), // purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            children: [
              Text(
                _displayName.isNotEmpty ? _displayName : widget.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap a message to see details',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: DottedBackgroundPainter(
                  dotColor: Colors.white.withOpacity(0.15),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: messageStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs;
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Start chatting with ${_displayName.isNotEmpty ? _displayName : widget.otherUserName}!',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data =
                            messages[messages.length - 1 - index].data()
                                as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUserId;

                        final senderName =
                            isMe
                                ? (data['senderName'] as String? ?? '')
                                : _nameFromEmail(widget.otherUserName);
                        final text = data['text'] as String? ?? '';
                        final timestamp = data['timestamp'] as Timestamp?;

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    isMe
                                        ? const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 144, 73, 221),
                                            Color.fromARGB(255, 142, 177, 236),
                                          ],
                                        )
                                        : LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            const Color.fromARGB(
                                              255,
                                              35,
                                              150,
                                              158,
                                            ),
                                          ],
                                        ),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 6.0,
                                      ),
                                      child: Text(
                                        senderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                  Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          isMe ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isMe
                                              ? Colors.white70
                                              : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFF6A11CB), // purple button
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => sendMessage(_controller.text),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.send, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  final Color dotColor;

  DottedBackgroundPainter({
    this.dotColor = const Color.fromRGBO(255, 255, 255, 0.15),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;

    const double spacing = 20.0;
    const double radius = 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
