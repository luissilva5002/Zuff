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

    setState(() => _isLoading = true);

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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home(selectedIndex: 3)),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration getInputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.secondary) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Checkbox(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: ClipOval(
                    child: Container(
                      height: 120,
                      width: 120,
                      color: Theme.of(context).colorScheme.secondary,
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo, size: 40)
                          : Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: getInputDecoration('Pet Name', Icons.pets),
                  validator: (value) => value!.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  decoration: getInputDecoration('Age', Icons.cake),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Enter age' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _speciesController,
                  decoration: getInputDecoration('Species', Icons.category),
                  validator: (value) => value!.isEmpty ? 'Enter species' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _breedController,
                  decoration: getInputDecoration('Breed', Icons.pets_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter breed' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _districtController,
                  decoration: getInputDecoration('District', Icons.location_city),
                  onChanged: (value) => setState(() => _selectedDistrict = value),
                  validator: (value) => value!.isEmpty ? 'Enter district' : null,
                ),
                const SizedBox(height: 12),

                buildCheckboxRow(
                  label: 'Vaccinated',
                  value: _isVaccinated,
                  onChanged: (value) => setState(() => _isVaccinated = value!),
                ),
                buildCheckboxRow(
                  label: 'For Adoption',
                  value: _isForAdoption,
                  onChanged: (value) => setState(() => _isForAdoption = value!),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: getInputDecoration('Birth Date', Icons.date_range),
                  onTap: _pickBirthDate,
                  validator: (value) => value!.isEmpty ? 'Select birth date' : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Pet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
