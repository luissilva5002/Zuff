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
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getConversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var conversations = snapshot.data!.docs;

          // Prepare futures for all users and images
          List<Future<Map<String, dynamic>>> futureUserData = conversations
              .map((conversation) async {
            var participants = (conversation['participants'] as List<dynamic>)
                .cast<String>();
            var otherUserId = participants.firstWhere((id) =>
            id != currentUserId);

            var userDoc = await FirebaseFirestore.instance.collection('users')
                .doc(otherUserId)
                .get();
            var userData = userDoc.data() ?? {};

            String name = userData['display_name'] ?? 'Unknown';
            String? imageUrl = await getProfileImageUrl(otherUserId);

            return {
              'conversation': conversation,
              'otherUserId': otherUserId,
              'displayName': name,
              'imageUrl': imageUrl,
            };
          }).toList();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(futureUserData),
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var items = usersSnapshot.data!;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  var conversation = item['conversation'];
                  var displayName = item['displayName'];
                  var imageUrl = item['imageUrl'];
                  var otherUserId = item['otherUserId'];

                  final imageProvider = (imageUrl != null)
                      ? NetworkImage(imageUrl)
                      : const AssetImage(
                      'assets/images/default_profile.png') as ImageProvider;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: imageProvider,
                    ),
                    title: Text(displayName),
                    subtitle: Text(conversation['lastMessage'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatPage(
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
      ),
    );
  }
}
