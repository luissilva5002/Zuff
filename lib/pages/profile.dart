import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';

//para teste -> usar firestore para dar load depois
final List<String> userPhotos = [
  'https://via.placeholder.com/150',
  'https://via.placeholder.com/160',
  'https://via.placeholder.com/170',
  'https://via.placeholder.com/180',
  'https://via.placeholder.com/190',
  'https://via.placeholder.com/200',
];

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: _buildAvatar(user)),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Nome não disponível',
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Minhas Fotos',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 300,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: userPhotos.map((url) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    return CircleAvatar(
      radius: 60,
      backgroundImage: user?.photoURL != null
          ? NetworkImage(user!.photoURL!)
          : const AssetImage('assets/default_profile.png') as ImageProvider,
      backgroundColor: Colors.grey.shade200,
    );
  }
}