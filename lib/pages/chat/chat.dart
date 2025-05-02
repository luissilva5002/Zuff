import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId; // Now nullable
  final String otherUserId;

  ChatPage({required this.conversationId, required this.otherUserId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _controller = TextEditingController();

  String? conversationId;
  String otherUserName = 'Loading...';

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId;
    fetchOtherUserName();
  }

  Future<void> fetchOtherUserName() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          otherUserName = data['display_name'] ?? 'Unknown';
        });
      } else {
        setState(() {
          otherUserName = 'Unknown';
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        otherUserName = 'Unknown';
      });
    }
  }

  Stream<QuerySnapshot>? getMessages() {
    if (conversationId == null) return null;
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String text = _controller.text.trim();
    _controller.clear();

    if (conversationId == null) {
      // Create new conversation
      DocumentReference conversationRef = await FirebaseFirestore.instance
          .collection('conversations')
          .add({
        'participants': [currentUserId, widget.otherUserId],
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        conversationId = conversationRef.id;
      });

      await conversationRef.collection('messages').add({
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Add to existing conversation
      var conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      await conversationRef.collection('messages').add({
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await conversationRef.update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: conversationId == null
                ? Center(child: Text('No messages yet. Say hi!'))
                : StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue :  Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(message['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
