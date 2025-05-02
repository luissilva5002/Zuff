import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zuff/pages/profile/suredelete.dart';
import 'package:zuff/pages/profile/surelogout.dart';
import '../../providers/themeprovider.dart';
import '../../theme/theme.dart';
import 'edit_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';


//para testing
final List<String> userPhotos = [
  'https://via.placeholder.com/150',
  'https://via.placeholder.com/160',
  'https://via.placeholder.com/170',
  'https://via.placeholder.com/180',
  'https://via.placeholder.com/190',
  'https://via.placeholder.com/200',
];

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});


  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final ImagePicker _picker = ImagePicker();
  User? user = FirebaseAuth.instance.currentUser;

  List<String> userPhotos = [];
  bool isLoadingPhotos = true;

  String name = 'unknown';
  String email = 'unknown';
  String creationDate = '${DateTime.now()}';

  User? currentUser;

  List<Map<String, dynamic>> userAnimals = [];
  bool isLoadingAnimals = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhotos();
    _loadUserInfo();
    _loadUserAnimals();
  }

  Future<void> _pickAndUploadGalleryPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final userId = user?.uid;
    if (userId == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/images/image_$timestamp.jpg');
      await ref.putFile(file);

      // Reload user photos
      await _loadUserPhotos();
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
      final ref = FirebaseStorage.instance.ref().child('users/${user!.uid}/photos');
      final ListResult result = await ref.listAll();

      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );

      setState(() {
        userPhotos = urls;
        isLoadingPhotos = false;
      });
    } catch (e) {
      debugPrint('Error loading photos: $e');
      setState(() {
        isLoadingPhotos = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String? savedName = prefs.getString('name');
      String? savedEmail = prefs.getString('email');
      String? savedCreationDate = prefs.getString('creationDate');

      if (savedName != null && savedEmail != null && savedCreationDate != null) {
        setState(() {
          name = savedName;
          email = savedEmail;
          creationDate = savedCreationDate;
        });
      } else {
        DocumentSnapshot userInfo = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userInfo.exists) {
          setState(() {
            name = userInfo['display_name'] ?? 'User123';
            email = userInfo['email'] ?? 'jonh.doe@gmail.com';
            creationDate = userInfo['created_time'] ?? '${DateTime.now()}';
          });

          await prefs.setString('name', name);
          await prefs.setString('email', email);
          await prefs.setString('creationDate', creationDate);
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final userId = user?.uid;
    if (userId == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId.jpg');
      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();

      // Update profile picture (optional)
      await user!.updatePhotoURL(imageUrl);
      await FirebaseAuth.instance.currentUser!.reload();

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      // Reload photo gallery
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
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pets') // Replace with your collection name
          .where('Owner', isEqualTo: user!.uid)
          .get();

      final animals = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() {
        userAnimals = animals;
        isLoadingAnimals = false;
      });
    } catch (e) {
      debugPrint('Error loading animals: $e');
      setState(() {
        isLoadingAnimals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Editar Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileWidget()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sair',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SureLogout(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: _buildAvatar()),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'Email não disponível',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bio curta ou status aqui...',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 120, // Altura ajustada para caber a lista de animais
              child: isLoadingAnimals
                  ? const Center(
                child: CircularProgressIndicator(), // Apenas um indicador centralizado
              )
                  : userAnimals.isEmpty
                  ? const Center(
                child: Text(
                  'No pets found.',
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: userAnimals.length,
                itemBuilder: (context, index) {
                  final animal = userAnimals[index];
                  return FutureBuilder<String>(
                    future: FirebaseStorage.instance
                        .ref(animal['Image']) // Caminho para a imagem no Firebase Storage
                        .getDownloadURL(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(); // Evita múltiplos indicadores
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error, color: Colors.red);
                      } else if (!snapshot.hasData) {
                        return const Icon(Icons.broken_image, color: Colors.grey);
                      }

                      final imageUrl = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: NetworkImage(imageUrl),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              animal['Name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 300,
                child: isLoadingPhotos
                    ? const Center(child: CircularProgressIndicator())
                    : userPhotos.isEmpty
                    ? const Center(
                  child: Text(
                    'Nenhuma foto enviada ainda.',
                    textAlign: TextAlign.center,
                  ),
                )
                    : GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...userPhotos.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, fit: BoxFit.cover),
                      );
                    }).toList(),
                    GestureDetector(
                      onTap: _pickAndUploadGalleryPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, size: 40, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text('ACCOUNT SETTINGS', textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
            SizedBox(height: 14,),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dark Theme'),
                ThemeSwitch(),
              ],
            ),
            Divider(),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () { },//() => launchUrl(Uri.parse('https://papayawhip-scorpion-787598.hostingersite.com/')),
                        child: Text(
                          'Help & Support',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: null),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const SureDelete(),
                          );
                        },
                        child: Text('Delete Account', style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : const AssetImage('assets/icons/user.png') as ImageProvider,
          backgroundColor: Colors.grey.shade200,
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Listening here is fine for rendering

    return Switch(
      value: themeProvider.themeData == darkMode, // True if darkMode is active
      onChanged: (bool value) {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
      activeTrackColor: Colors.grey,
      activeColor: Colors.black,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey,
    );
  }
}