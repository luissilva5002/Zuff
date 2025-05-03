import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/petprofile.dart';
import '../profile/menu.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage()));
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: _buildAvatar()),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(bio, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 152,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('My Pets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: userAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = userAnimals[index];
                          final petId = animal['id'];
                          final imagePath = animal['Image'];

                          if (imagePath is! String || imagePath.isEmpty) {
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
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                                      child: const Icon(Icons.pets),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(animal['Name'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }

                          return FutureBuilder<String>(
                            future: FirebaseStorage.instance.ref(imagePath).getDownloadURL(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(width: 70);
                              } else if (snapshot.hasError || !snapshot.hasData) {
                                return const Icon(Icons.error, color: Colors.red);
                              }
                              final imageUrl = snapshot.data!;
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
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundImage: NetworkImage(imageUrl),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(animal['Name'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(thickness: 2, height: 2, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 300,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...userPhotos.map((url) {
                            return GestureDetector(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
