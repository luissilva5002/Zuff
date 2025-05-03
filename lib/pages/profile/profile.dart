import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zuff/pages/profile/petprofile.dart';
import 'add_pet.dart';
import 'menu.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<Profile> {
  final ImagePicker _picker = ImagePicker();
  User? user = FirebaseAuth.instance.currentUser;

  List<String> userPhotos = [];
  bool isLoading = true;

  String name = 'unknown';
  String bio = 'No Bio...';
  String email = 'unknown';
  String creationDate = '${DateTime.now()}';

  User? currentUser;

  List<Map<String, dynamic>> userAnimals = [];

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

  Future<void> _pickAndUploadGalleryPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || user == null) return;

    final file = File(pickedFile.path);
    final userId = user!.uid;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/photos/image_$timestamp.jpg');
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();

    } catch (e) {
      debugPrint('Error uploading image to gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar imagem')),
      );
    }
  }
  Future<void> _loadUserPhotos() async {
    if (user == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      final ref = FirebaseStorage.instance.ref().child('users/${user!.uid}/photos');
      final ListResult result = await ref.listAll();

      final urls = await Future.wait(result.items.map((item) => item.getDownloadURL()));


      setState(() {
        userPhotos = urls;
        isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading photos: $e');


      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    setState(() {
      isLoading = true;
    });

    DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

    if (userInfo.exists) {
        setState(() {
          name = userInfo['display_name'] ?? 'User123';
          bio = userInfo['bio'] ?? 'No Bio...';
          email = userInfo['email'] ?? 'john.doe@gmail.com';
          creationDate = userInfo['created_time'] ?? '${DateTime.now()}';
        });
    }

    setState(() {
      isLoading = false;
    });
  }
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || user == null) return;

    final file = File(pickedFile.path);
    final userId = user!.uid;

    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await user!.updatePhotoURL(imageUrl);
      await FirebaseAuth.instance.currentUser!.reload();

      setState(() {
        user = FirebaseAuth.instance.currentUser;
        isLoading = false;
      });

      await _loadUserPhotos();

    } catch (e) {
      debugPrint('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
    }
  }

  Future<void> _loadUserAnimals() async {
    if (user == null) return;


    try {
      setState(() => isLoading = true);

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('Owner', isEqualTo: user!.uid)
          .get();

      final animals = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();


      setState(() {
        userAnimals = animals;
        isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading animals: $e');

      setState(() => isLoading = false);
    }
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color:  Theme.of(context).colorScheme.primary,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
              );
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
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                bio,
                style: TextStyle(fontSize: 14, color:  Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 152,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Pets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: userAnimals.length + 1,
                        itemBuilder: (context, index) {
                          // Add Pet button at the END
                          if (index == userAnimals.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddPetPage()),
                                  );
                                },
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      child: Icon(Icons.add, size: 35),
                                    ),
                                    SizedBox(height: 8),
                                    Text('Add Pet', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }

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
                                    Text(
                                      '${animal['Name'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
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
                                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                                        radius: 35,
                                        backgroundImage: NetworkImage(imageUrl),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${animal['Name'] ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 12),
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
                  ),
                ],
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
                    GestureDetector(
                      onTap: _pickAndUploadGalleryPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color:  Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, size: 40, color:  Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    // Then display the photos (if any)
                    ...userPhotos.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}