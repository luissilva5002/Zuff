import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      // If image doesn't exist or an error occurs, return null
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getConversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

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

                  return FutureBuilder<String?>(
                    future: getProfileImageUrl(otherUserId),
                    builder: (context, imageSnapshot) {
                      final imageProvider = (imageSnapshot.connectionState == ConnectionState.done &&
                          imageSnapshot.hasData &&
                          imageSnapshot.data != null)
                          ? NetworkImage(imageSnapshot.data!)
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: imageProvider,
                        ),
                        title: Text(otherUserName),
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
                },
              );
            },
          );
        },
      ),
    );
  }
}
