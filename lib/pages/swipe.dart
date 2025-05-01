import 'package:flutter/material.dart';

// Pet model definition
class Pet {
  final String name;
  final String location;
  final int age;
  final String imageUrl;

  Pet({required this.name, required this.location, required this.age, required this.imageUrl});
}

class PetSwipe extends StatefulWidget {
  @override
  _PetSwipeState createState() => _PetSwipeState();
}

class _PetSwipeState extends State<PetSwipe> {
  int currentPetIndex = 0;
  final List<Pet> _pets = [
    Pet(name: "Luna", location: "Lisbon", age: 2, imageUrl: "https://www.example.com/image1.jpg"),
    Pet(name: "Buddy", location: "Porto", age: 4, imageUrl: "https://www.example.com/image2.jpg"),
    Pet(name: "Max", location: "Coimbra", age: 3, imageUrl: "https://www.example.com/image3.jpg"),
  ];

  void accept(Pet pet) {
    print("Accepted ${pet.name}");
  }

  void reject(Pet pet) {
    print("Rejected ${pet.name}");
  }

  Widget _buildPetCard() {
    // Ensure there's at least one pet to swipe through
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

        // Remove the pet from the list after being dismissed
        setState(() {
          _pets.removeAt(currentPetIndex); // Remove the current pet
          if (currentPetIndex >= _pets.length) {
            currentPetIndex = _pets.length - 1; // Adjust the index if needed
          }
        });
      },
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 40),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.close, color: Colors.white, size: 40),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox.expand(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      pet.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 40,
                          ),
                        );
                      },
                    )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(pet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${pet.age} years old · ${pet.location}',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700])),
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
