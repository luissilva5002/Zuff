import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _selectedDistrict;
  bool _isVaccinated = false;
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

    try {
      String? imagePath;
      if (_imageFile != null) {
        // Create a file name using the pet's name
        final fileName = '${_nameController.text.replaceAll(' ', '_').toLowerCase()}.jpg';
        final ref = FirebaseStorage.instance.ref().child('pets/$fileName');
        await ref.putFile(_imageFile!);
        imagePath = 'pets/$fileName'; // Save the file path
      }

      await FirebaseFirestore.instance.collection('pets').add({
        'Adoption': false, // Verify later
        'Name': _nameController.text,
        'Age': int.tryParse(_ageController.text) ?? 0,
        'Species': _speciesController.text,
        'Breed': _breedController.text,
        'District': _selectedDistrict,
        'Vaccinated': _isVaccinated,
        'BirthDate': _birthDateController.text,
        'Image': imagePath ?? '', // Save the file path
        'Owner': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet added successfully!')),
      );

      Navigator.pop(context);
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet\'s name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet\'s age';
                    }
                    return null;
                  },
                ),
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
                TextFormField(
                  controller: TextEditingController(text: _selectedDistrict),
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
                Row(
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
                  child: const Text('Add Pet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}