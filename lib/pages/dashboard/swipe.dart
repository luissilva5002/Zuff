import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// Pet model definition (imageUrl removed)
class Pet {
  final String name;
  final String location;
  final int age;
  final String imagePath;
  final String? species;
  final String? breed;
  final bool? vaccinated;
  final String? birthDate;
  final String? owner;

  Pet({
    required this.name,
    required this.location,
    required this.age,
    required this.imagePath,
    this.species,
    this.breed,
    this.vaccinated,
    this.birthDate,
    this.owner,
  });
}

class PetSwipe extends StatefulWidget {
  const PetSwipe({super.key});

  @override
  _PetSwipeState createState() => _PetSwipeState();
}
class _PetSwipeState extends State<PetSwipe> {
  int currentPetIndex = 0;
  List<Pet> _pets = []; // List to store fetched pets
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    fetchPets(); // Fetch pet data from Firestore when widget is initialized
  }

  Future<void> fetchPets() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('Adoption', isEqualTo: true)
          .get();

      setState(() {
        _pets = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return Pet(
            name: data['Name'] ?? 'Unknown',
            location: data['Location'] ?? 'Unknown',
            age: data['Age'] ?? 'Unknown',
            imagePath: data['Image'] ?? '',
            species: data['Species'],
            breed: data['Breed'],
            vaccinated: data['Vaccinated'],
            birthDate: data['BirthDate'],
            owner: data['Owner'],
          );
        }).toList();
      });
    } catch (e) {
      print("Error fetching pets: $e");
    }
  }

  void accept(Pet pet) {
    print("Accepted ${pet.name}");
  }

  void reject(Pet pet) {
    print("Rejected ${pet.name}");
  }

  Future<String> getImageUrl(String imagePath) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(imagePath);
      String imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error fetching image: $e");
      return "";
    }
  }
  Widget _buildPetCard() {
    if (_pets.isEmpty) {
      return const Center(
          child: Text("No more pets!", style: TextStyle(fontSize: 22)));
    }

    final pet = _pets[currentPetIndex];

    return Dismissible(
      key: ValueKey(pet.name),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          accept(pet);
        } else {
          reject(pet);
        }

        setState(() {
          _pets.removeAt(currentPetIndex);
          if (_pets.isEmpty) {
            currentPetIndex = 0;
          } else if (currentPetIndex >= _pets.length) {
            currentPetIndex = _pets.length - 1;
          }
          _showBack = false; // Reset flip state when card changes
        });
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.green, size: 40),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.close, color: Colors.red, size: 40),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.8,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showBack = !_showBack;
                });
              },
              child: _showBack ? _buildBack(pet) : _buildFront(pet),
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildFront(Pet pet) {
      return Container(
        key: const ValueKey('front'),
        width: double.infinity, // Full width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              child: FutureBuilder<String>(
                future: getImageUrl(pet.imagePath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(child: Icon(Icons.error));
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          snapshot.data!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pet.age} years old · ${pet.location}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildBack(Pet pet) {
      return Container(
        key: const ValueKey('back'),
        width: double.infinity, // Full width
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${pet.name}'),
                Text('Age: ${pet.age}'),
                Text('Location: ${pet.location}'),
                Text('Species: ${pet.species ?? "Unknown"}'),
                Text('Breed: ${pet.breed ?? "Unknown"}'),
                Text('Vaccinated: ${pet.vaccinated == true ? "Yes" : "No"}'),
                Text('Birth Date: ${pet.birthDate ?? "Unknown"}'),
                Text('Owner: ${pet.owner ?? "Unknown"}'),
                const SizedBox(height: 10),
                const Text(
                  'Adoption Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• Ensure a safe and stable home\n'
                      '• Budget for vet care and food\n'
                      '• Plan time for daily care and bonding',
                ),
              ],
            ),
          ),
        ),
      );
    }



  @override
  Widget build(BuildContext context) {
    return _buildPetCard();
  }
}