import 'package:flutter/material.dart';

// Pet model definition (imageUrl removed)
class Pet {
  final String name;
  final String location;
  final int age;
  final String imageUrl;

  Pet({
    required this.name,
    required this.location,
    required this.age,
    required this.imageUrl,
  });
}


class PetSwipe extends StatefulWidget {
  @override
  _PetSwipeState createState() => _PetSwipeState();
}

class _PetSwipeState extends State<PetSwipe> {
  int currentPetIndex = 0;

  //https://firebasestorage.googleapis.com/v0/b/<bucket-name>/o/<file-path>?alt=media&token=<access-token>

  final List<Pet> _pets = [
    Pet(
      name: "Luna",
      location: "Lisbon",
      age: 2,
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/zuff-b139f.appspot.com/o/luna.jpeg?alt=media&token=d6188725-1d50-4529-8002-91db0850b43a"

    ),
    Pet(
      name: "Buddy",
      location: "Porto",
      age: 4,
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/zuff-b139f.appspot.com/o/buddy.jpeg?alt=media&token=d6188725-1d50-4529-8002-91db0850b43a",
    ),
    Pet(
      name: "Max",
      location: "Coimbra",
      age: 3,
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/zuff-b139f.appspot.com/o/max.jpeg?alt=media&token=d6188725-1d50-4529-8002-91db0850b43a",
    ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    pet.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        height: 200,
                        child: Center(child: Icon(Icons.error)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(pet.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${pet.age} years old · ${pet.location}', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
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