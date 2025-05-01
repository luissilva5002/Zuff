import 'package:flutter/material.dart';

// Pet model definition (imageUrl removed)
class Pet {
  final String name;
  final String location;
  final int age;

  Pet({required this.name, required this.location, required this.age});
}

class PetSwipe extends StatefulWidget {
  @override
  _PetSwipeState createState() => _PetSwipeState();
}

class _PetSwipeState extends State<PetSwipe> {
  int currentPetIndex = 0;

  final List<Pet> _pets = [
    Pet(name: "Luna", location: "Lisbon", age: 2),
    Pet(name: "Buddy", location: "Porto", age: 4),
    Pet(name: "Max", location: "Coimbra", age: 3),
  ];

  void accept(Pet pet) {
    print("Accepted ${pet.name}");
  }

  void reject(Pet pet) {
    print("Rejected ${pet.name}");
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${pet.age} years old · ${pet.location}',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  ],
                ),
              ),
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