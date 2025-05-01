import 'package:flutter/material.dart';
import 'swipe.dart'; // Import the swipe logic
import 'add_pet.dart'; // Import the add pet functionality

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Pet Adoption'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to the add pet page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPet()),
              );
            },
          ),
        ],
      ),
      body: PetSwipe(),
    );
  }
}
