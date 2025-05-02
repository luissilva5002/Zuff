import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// Pet model definition (imageUrl removed)
class Pet {
  final String name;
  final String location;
  final int age;
  final String imagePath; // Use path of the image in Firebase Storage

  Pet({
    required this.name,
    required this.location,
    required this.age,
    required this.imagePath,
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

  @override
  void initState() {
    super.initState();
    fetchPets(); // Fetch pet data from Firestore when widget is initialized
  }

  // Fetch pet data from Firestore
  Future<void> fetchPets() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('pets').get();
      setState(() {
        _pets = querySnapshot.docs.map((doc) {
          return Pet(
            name: doc['Name'],
            location: doc['Location'],
            age: doc['Age'],
            imagePath: doc['Image'],
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

  // Fetch image from Firebase Storage and get the URL
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
      return Center(child: Text("No more pets!", style: TextStyle(fontSize: 22)));
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
          if (currentPetIndex >= _pets.length) {
            currentPetIndex = _pets.length - 1;
          }
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
        child: SizedBox.expand(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
              children: [
                // Image section with expanded space
                FutureBuilder<String>(
                  future: getImageUrl(pet.imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Icon(Icons.error)),
                      );
                    } else if (snapshot.hasData) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Add padding around the image
                          child: Align(
                            alignment: Alignment.center, // Center the image
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16), // Set the border radius for rounding corners
                              child: Image.network(
                                snapshot.data!,
                                width: double.infinity,
                                fit: BoxFit.contain, // Prevent cropping, scale the image
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Icon(Icons.error)),
                      );
                    }
                  },
                ),
                // Text content placed at the bottom of the card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(pet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${pet.age} years old · ${pet.location}', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
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