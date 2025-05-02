import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuff/pages/profile/profile.dart';

import '../../home.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  String? _selectedDistrict;
  bool _isVaccinated = false;
  bool _isForAdoption = false;
  File? _imageFile;
  bool _isLoading = false;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final birthDate = DateFormat('yyyy-MM-dd').parse(_birthDateController.text);
    final currentDate = DateTime.now();

    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
      age--;
    }

    try {
      String? imagePath;
      if (_imageFile != null) {
        final fileName = '${_nameController.text.replaceAll(' ', '_').toLowerCase()}.jpg';
        final ref = FirebaseStorage.instance.ref().child('pets/$fileName');
        await ref.putFile(_imageFile!);
        imagePath = 'pets/$fileName';
      }

      await FirebaseFirestore.instance.collection('pets').add({
        'Adoption': _isForAdoption,
        'Name': _nameController.text,
        'Species': _speciesController.text,
        'Breed': _breedController.text,
        'District': _selectedDistrict,
        'Vaccinated': _isVaccinated,
        'BirthDate': _birthDateController.text,
        'Image': imagePath ?? '',
        'Owner': userId,
        'Age': age,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet added successfully!')),
      );

      // Navigate to Home
      if (FirebaseAuth.instance.currentUser != null) {
        // If the user is authenticated, go to Home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );

        // Navigate to Profile after going to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );

        // Clear the stack and go to Profile, this will remove Home from the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
              (Route<dynamic> route) => false, // Removes all the previous routes
        );
      } else {
        // If the user is not authenticated, go to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: ClipOval(
                      child: Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey[300],
                        child: _imageFile == null
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.black54)
                            : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Pet Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pet\'s name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pet\'s age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _speciesController,
                    decoration: const InputDecoration(labelText: 'Species'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pet\'s species';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(labelText: 'Breed'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pet\'s breed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'District'),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a district';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isVaccinated,
                        onChanged: (value) {
                          setState(() {
                            _isVaccinated = value!;
                          });
                        },
                      ),
                      const Text('Vaccinated'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isForAdoption,
                        onChanged: (value) {
                          setState(() {
                            _isForAdoption = value!;
                          });
                        },
                      ),
                      const Text('For Adoption'),
                    ],
                  ),

                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Birth Date'),
                    onTap: _pickBirthDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a birth date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Add Pet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
