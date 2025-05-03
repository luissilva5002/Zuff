import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/petprofile.dart';

class ProfileDisplay extends StatefulWidget {
  final String userId;

  const ProfileDisplay({super.key, required this.userId});

  @override
  State<ProfileDisplay> createState() => _ProfileDisplayState();
}

class _ProfileDisplayState extends State<ProfileDisplay> {
  List<String> userPhotos = [];
  List<Map<String, dynamic>> userAnimals = [];

  String name = 'unknown';
  String bio = 'No Bio...';
  String email = 'unknown';
  String creationDate = '${DateTime.now()}';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProfileData();
  }

  Future<void> _initializeProfileData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadUserPhotos(),
      _loadUserInfo(),
      _loadUserAnimals(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadUserPhotos() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/${widget.userId}/photos');
      final result = await ref.listAll();
      final urls = await Future.wait(result.items.map((item) => item.getDownloadURL()));
      userPhotos = urls;
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userInfo.exists) {
        final data = userInfo.data()!;
        name = data['display_name'] ?? 'User123';
        bio = data['bio'] ?? 'No Bio...';
        email = data['email'] ?? 'john.doe@gmail.com';
        creationDate = data['created_time'] ?? '${DateTime.now()}';
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _loadUserAnimals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('Owner', isEqualTo: widget.userId)
          .get();

      userAnimals = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error loading animals: $e');
    }
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: userPhotos.isNotEmpty
          ? NetworkImage(userPhotos.first)
          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text("Profile"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(child: _buildAvatar()),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(bio, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(height: 32),

            /// My Pets Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('My Pets', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: userAnimals.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final animal = userAnimals[index];
                  final petId = animal['id'];
                  final imagePath = animal['Image'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetProfilePage(id: petId),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          imagePath != null && imagePath.isNotEmpty
                              ? FutureBuilder<String>(
                            future: FirebaseStorage.instance.ref(imagePath).getDownloadURL(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircleAvatar(radius: 35, child: CircularProgressIndicator(strokeWidth: 2));
                              } else if (snapshot.hasError || !snapshot.hasData) {
                                return const CircleAvatar(radius: 35, child: Icon(Icons.error));
                              }
                              return CircleAvatar(
                                radius: 35,
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            },
                          )
                              : const CircleAvatar(
                            radius: 35,
                            child: Icon(Icons.pets),
                          ),
                          const SizedBox(height: 8),
                          Text(animal['Name'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Divider(thickness: 1.5, color: Theme.of(context).colorScheme.tertiary),
            ),

            /// Photos Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: userPhotos.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(userPhotos[index], fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
