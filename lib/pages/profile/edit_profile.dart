import 'package:flutter/material.dart';

class EditProfileWidget extends StatelessWidget {
  const EditProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF009688),
        centerTitle: true,
      ),
      body: Center(  // Centers everything vertically
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,  // Center column content vertically
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,  // Makes the column take only necessary space
              children: [
                const Text(
                  'Update your profile information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                // Name Field
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black,),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Bio Field
                const TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us something about yourself...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black,),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 24),
                // Save Button
                ElevatedButton(
                  onPressed: () {
                    // Save profile changes logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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