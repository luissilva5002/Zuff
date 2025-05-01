import 'package:flutter/material.dart';

class AddPet extends StatefulWidget {
  const AddPet({super.key});

  @override
  State<AddPet> createState() => _AddPetState();
}

class _AddPetState extends State<AddPet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  void _addPet() {
    // Here you would add the logic to save the pet to Firebase.
    print("Adding pet: ${_nameController.text}");
    // Example Firebase code
    // FirebaseFirestore.instance.collection('pets').add({
    //   'name': _nameController.text,
    //   'location': _locationController.text,
    //   'age': int.parse(_ageController.text),
    //   'imageUrl': _imageUrlController.text,
    // });

    // After adding the pet, pop the screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Pet Name'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addPet,
              child: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }
}
