import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';


class PetProfilePage extends StatelessWidget {
  final Map<String, dynamic> data;

  const PetProfilePage({required this.data, super.key});

  Future<String> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['Name'] ?? 'Unknown';
    final int age = data['Age'] ?? 0;
    final String location = data['Location'] ?? 'Unknown location';
    final String species = data['Species'] ?? 'Unknown species';
    final String breed = data['Breed'] ?? 'Unknown breed';
    final bool vaccinated = data['Vaccinated'] ?? false;
    final String birthDate = data['BirthDate'] ?? 'Unknown date';
    final String owner = data['Owner'] ?? 'Unknown owner';
    final String imagePath = data['Image'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                      const Spacer(),
                      const Icon(Icons.pets, color: Colors.pinkAccent),
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
      ),
    );
  }
}
