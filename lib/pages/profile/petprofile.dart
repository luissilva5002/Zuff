import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PetProfilePage extends StatelessWidget {
  final String id;

  const PetProfilePage({required this.id, super.key});

  Future<String> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Future<Map<String, dynamic>> _getPetData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('pets').doc(id).get();
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getPetData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Error fetching pet data.'));
          }

          final petData = snapshot.data!;
          final String name = petData['Name'] ?? 'Unknown';
          final int age = petData['Age'] ?? 'Unknown';
          final String species = petData['Species'] ?? 'Unknown';
          final String breed = petData['Breed'] ?? 'Unknown';
          final String location = petData['Location'] ?? 'Unknown';
          final String gender = petData['gender'] ?? 'Unknown';
          final bool vaccinated = petData['Vaccinated'] ?? false;
          final String birthDate = petData['BirthDate'] ?? 'Unknown';
          final String owner = petData['Owner'] ?? 'Unknown';
          final String imagePath = petData['Image'] ?? '';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _getImageUrl(imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        height: 400,
                        color: Colors.grey,
                        child: const Icon(Icons.broken_image, size: 100, color: Colors.white),
                      );
                    }

                    final photoUrl = snapshot.data!;
                    return Image.network(
                      photoUrl,
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$name, $age',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('$species • $breed',
                              style: TextStyle(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.error, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('$gender',
                              style: TextStyle(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(location, style: TextStyle(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(vaccinated ? "Vaccinated" : "Not vaccinated",
                              style: TextStyle(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Born on: $birthDate\nOwner: $owner',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
