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

  Future<String> _getOwnerName(String ownerId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['display_name'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
          final bool vaccinated = petData['Vaccinated'] ?? false;
          final String birthDate = petData['BirthDate'] ?? 'Unknown';
          final String ownerId = petData['Owner'] ?? 'Unknown';
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
                      return const SizedBox(
                        height: 400,
                        child: Icon(Icons.broken_image, size: 100),
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
                          const Icon(Icons.pets, size: 16),
                          const SizedBox(width: 6),
                          Text('$species • $breed'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 6),
                          Text(location),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16),
                          const SizedBox(width: 6),
                          Text(vaccinated ? "Vaccinated" : "Not vaccinated"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: _getOwnerName(ownerId),
                        builder: (context, ownerSnapshot) {
                          final ownerName = (ownerSnapshot.connectionState == ConnectionState.done && ownerSnapshot.hasData)
                              ? ownerSnapshot.data!
                              : 'Loading...';
                          return Text(
                            'Born on: $birthDate\nOwner: $ownerName',
                            style: const TextStyle(fontSize: 16),
                          );
                        },
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