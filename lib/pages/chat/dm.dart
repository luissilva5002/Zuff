import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart';

class DMPage extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> getConversations() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getConversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          print(snapshot.data?.size);
          print(currentUserId);

          var conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
              itemBuilder: (context, index) {
                var conversation = conversations[index];
                var participants = (conversation['participants'] as List<dynamic>).cast<String>();
                var otherUserId = participants.firstWhere((id) => id != currentUserId);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return ListTile(title: Text('Loading...'));
                    }

                    var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    String otherUserName = userData?['display_name'] ?? 'Unknown';

                    return ListTile(
                      title: Text('Chat with $otherUserName'),
                      subtitle: Text(conversation['lastMessage'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              conversationId: conversation.id,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
          );
        },
      ),
    );
  }
}