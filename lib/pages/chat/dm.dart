import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'chat.dart';
class UserSearchPage extends StatefulWidget {
  final String currentUserId;

  UserSearchPage({required this.currentUserId});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  String searchQuery = '';
  List<DocumentSnapshot> searchResults = [];

  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      // If image doesn't exist or an error occurs, return null
      return null;
    }
  }

  void performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();

      final lowerQuery = query.toLowerCase();

      final filtered = snapshot.docs.where((doc) {
        final name = (doc['display_name'] ?? '').toString().toLowerCase();
        final uid = doc.id;

        return uid != widget.currentUserId && name.contains(lowerQuery);
      }).toList();

      setState(() {
        searchResults = filtered;
      });
    } catch (e) {
      print('Search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
                if (value.isNotEmpty) performSearch(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var user = searchResults[index];
                return FutureBuilder<String?>(
                  future: getProfileImageUrl(user.id),
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
                      title: Text(user['display_name']),
                        onTap: () async {
                          final existingConversation = await FirebaseFirestore.instance
                              .collection('conversations')
                              .where('participants', arrayContains: widget.currentUserId)
                              .get();

                          String? matchedConversationId;

                          for (var doc in existingConversation.docs) {
                            final participants = List<String>.from(doc['participants']);
                            if (participants.contains(user.id)) {
                              matchedConversationId = doc.id;
                              break;
                            }
                          }

                          // Optional: create conversation if not found
                          if (matchedConversationId == null) {
                            final newConversation = await FirebaseFirestore.instance.collection('conversations').add({
                              'participants': [widget.currentUserId, user.id],
                              'lastMessage': '',
                              'lastMessageTimestamp': FieldValue.serverTimestamp(),
                            });
                            matchedConversationId = newConversation.id;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                conversationId: matchedConversationId!,
                                otherUserId: user.id,
                              ),
                            ),
                          );
                        }
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
      appBar: AppBar(
        title: Text('Your Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserSearchPage(currentUserId: currentUserId)),
              );
            },
          ),
        ],
      ),
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
