import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SureDelete extends StatefulWidget {
  const SureDelete({super.key});

  @override
  State<SureDelete> createState() => _SureDeleteState();
}

class _SureDeleteState extends State<SureDelete> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> deleteUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).delete();
    } else {
      print('No user is currently signed in');
    }
  }


  Future<void> reauthenticateUser(String email, String password) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Failed to re-authenticate: ${e.message}');
      throw e;
    }
  }

  Future<void> deleteUserAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    try {
      await user.delete();
      print('User account deleted successfully');
      Navigator.of(context).pop(); // Close the dialog after deleting
    } on FirebaseAuthException catch (e) {
      print('Failed to delete user: ${e.message}');
      throw e;
    }
  }

  Future<void> _confirmDelete() async {
    deleteUserData();
    try {
      await reauthenticateUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await deleteUserAccount();

    } catch (e) {
      // Handle errors and provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure the content fits within the dialog
        children: [
          const Text('Are you sure you want to delete this account? All data will be lost'),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
          ),
          onPressed: _confirmDelete,
          child: const Text('Delete',style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}