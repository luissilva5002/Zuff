import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:zuff/services/age.dart';

import '../../home.dart';
class Pet {
  final String id;
  final String name;
  final String location;
  final int age;
  final String imagePath;
  final String? species;
  final String? breed;
  final bool? vaccinated;
  final String? birthDate;
  final String? ownerName;
  final String? ownerId; // Add this

  Pet({
    required this.name,
    required this.location,
    required this.age,
    required this.imagePath,
    required this.species,
    required this.breed,
    required this.vaccinated,
    required this.birthDate,
    required this.ownerName,
    required this.ownerId, // Include here
    required this.id,
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
  final ageService = Age();
  String OwnerID = '';

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  Future<void> fetchPets() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    List<dynamic> accepted = userDoc['accepted'] ?? [];
    List<dynamic> rejected = userDoc['rejected'] ?? [];

    Set<String> excludedPetIds = {
      ...accepted.map((e) => e.toString()),
      ...rejected.map((e) => e.toString())
    };

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('Adoption', isEqualTo: true)
        .get();

    List<Pet> filteredPets = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (excludedPetIds.contains(doc.id)) {
        continue;
      }

      final birthDateStr = data['BirthDate'] ?? '';
      final int age = ageService.calculateAge(birthDateStr);

      String ownerName = 'Unknown';
      String? ownerId = data['Owner'];

      if (ownerId != null) {
        try {
          DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .get();

          if (ownerDoc.exists && ownerDoc.data() != null) {
            ownerName = ownerDoc['display_name'] ?? 'Unknown';
          }
        } catch (e) {
          print('Error fetching owner name: $e');
        }
      } else {
        print('No owner ID found for pet: ${doc.id}');
      }

      filteredPets.add(Pet(
        id: doc.id,
        name: data['Name'] ?? 'Unknown',
        location: data['District'] ?? 'Unknown',
        imagePath: data['Image'] ?? '',
        species: data['Species'],
        breed: data['Breed'],
        ownerName: ownerName,
        ownerId: ownerId,
        vaccinated: data['Vaccinated'],
        birthDate: birthDateStr,
        age: age,
      ));
    }

    setState(() {
      _pets = filteredPets;
    });
  }

  Future<void> accept(Pet pet) async {
    print("Accepted ${pet.name}");

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String? shelterUserId = pet.ownerId;

    // Add pet document ID to "accepted"
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'accepted': FieldValue.arrayUnion([pet.id]),
    });

    // Check if conversation exists
    QuerySnapshot existing = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    DocumentSnapshot? existingConversation;
    for (var doc in existing.docs) {
      List participants = doc['participants'];
      if (participants.contains(shelterUserId)) {
        existingConversation = doc;
        break;
      }
    }

    DocumentReference conversationRef;

    if (existingConversation != null) {
      conversationRef = existingConversation.reference;
    } else {
      conversationRef = await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [currentUserId, shelterUserId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    await conversationRef.collection('messages').add({
      'senderId': currentUserId,
      'text': "Hi! I'm interested in adopting ${pet.name}.",
      'timestamp': FieldValue.serverTimestamp(),
    });

    await conversationRef.update({
      'lastMessage': "Hi! I'm interested in adopting ${pet.name}.",
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reject(Pet pet) async {
    print("Rejected ${pet.name}");

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Add pet document ID to "rejected"
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'rejected': FieldValue.arrayUnion([pet.id]),
    });
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

  Future<String> fetchOtherUserName(String ownerId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data['display_name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown';
    }
  }

  Future<void> _clearPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Update the Firebase user's document to empty the "pets" array
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'rejected': []});

        // Optionally, clear the local _pets array as well
        setState(() {
          _pets.clear();
        });

        // Navigate to Home
        if (FirebaseAuth.instance.currentUser != null) {

          // Clear the stack and go to Profile, this will remove Home from the stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
                (Route<dynamic> route) => false, // Removes all the previous routes
          );
        } else {
          // If the user is not authenticated, go to Profile page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing pets: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildPetCard() {
    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // This will center the children vertically
          crossAxisAlignment: CrossAxisAlignment.center, // This will center the children horizontally
          children: [
            const Text("No more pets!", style: TextStyle(fontSize: 22)),
            GestureDetector(
              onTap: _clearPets,
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Reload already seen pets",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
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
      width: double.infinity,
      height: double.infinity, // Required to calculate available vertical space
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center image vertically in available space
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FutureBuilder<String>(
                    future: getImageUrl(pet.imagePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Icon(Icons.error);
                      } else {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            snapshot.data!,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.55,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pet.age} years old · ${pet.location}',
                  textAlign: TextAlign.center,
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Needed for vertical centering
            crossAxisAlignment: CrossAxisAlignment.start, // Text aligned to the left
            children: [
              _infoRow(Icons.pets, 'Name', pet.name),
              _infoRow(Icons.calendar_today, 'Age', pet.age.toString()),
              _infoRow(Icons.location_on, 'Location', pet.location),
              _infoRow(Icons.category, 'Species', pet.species ?? 'Unknown'),
              _infoRow(Icons.pets_outlined, 'Breed', pet.breed ?? 'Unknown'),
              _infoRow(Icons.health_and_safety, 'Vaccinated', pet.vaccinated == true ? 'Yes' : 'No'),
              _infoRow(Icons.cake, 'Birth Date', pet.birthDate ?? 'Unknown'),
              _infoRow(Icons.person, 'Owner', pet.ownerName ?? 'Unknown'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPetCard();
  }
}