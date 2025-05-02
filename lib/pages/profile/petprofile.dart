import 'package:flutter/material.dart';

class PetProfilePage extends StatelessWidget {
  final Map<String, dynamic> data;

  const PetProfilePage({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final String name = data['name'];
    final int age = data['age'];
    final String location = data['location'];
    final String species = data['species'];
    final String breed = data['breed'];
    final bool vaccinated = data['vaccinated'];
    final String birthDate = data['birthDate'];
    final String owner = data['owner'];
    final String photoUrl = data['photoUrl'];
    final String adoptionTips = data['adoptionTips'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              photoUrl,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.pets, color: Colors.pinkAccent),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.pets, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('$species • $breed',
                          style: TextStyle(color: Colors.grey[800])),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(location, style: TextStyle(color: Colors.grey[800])),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(vaccinated ? "Vaccinated" : "Not vaccinated",
                          style: TextStyle(color: Colors.grey[800])),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Born on: $birthDate\nOwner: $owner',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Divider(),
                  const Text(
                    'Adoption Tips',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 8),
                  Text(
                    adoptionTips,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
