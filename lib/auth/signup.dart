import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zuff/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuff/main.dart';
import '../utils.dart';

class SignUpPage extends StatefulWidget {

  const SignUpPage({
    super.key
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  User? currentUser;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordVisible1 = false;

  Future<void> uploadInfo() async {
    List<String> accepted = [''];
    List<String> rejected = [''];

    var now = DateTime.now();
    var formatter = DateFormat();
    String date = formatter.format(now);
    currentUser = FirebaseAuth.instance.currentUser;

    try {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .set({
          'email': emailController.text.trim(),
          'created_time': date,
          'display_name': nameController.text.trim(),
          'accepted': accepted, // Store accepted array in Firestore
          'rejected': rejected, // Store rejected array in Firestore
        });
      }
    } catch (e) {
      print("Error uploading info: $e");
    }
  }


  Future signUp() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Now the user is created, so upload info
      await uploadInfo();

      // Close the loading dialog
      Navigator.of(context).pop();

      // Navigate to the first screen
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      Utils.showSnackBar(e.message);
      Navigator.of(context).pop();
    }
  }


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF009688),
              Color(0xFF94a9a7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Zuff',
                    style: TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, fontFamily: 'RobotoSlab',),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Get Started",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30),
                          ),
                          const SizedBox(height: 16,),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                            ),
                            style: TextStyle(color: Colors.black),
                            keyboardType: TextInputType.name,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'You must enter a name';
                              } else {
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                            ),
                            style: TextStyle(color: Colors.black),
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(color: Colors.black),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) => value != null && value.length < 6
                                ? 'Password must be at least 6 characters long'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible1 ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible1 = !_isPasswordVisible1;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible1,
                            style: TextStyle(color: Colors.black),

                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) => value != null && value.length < 6
                                ? 'Password must be at least 6 characters long'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF009688),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: const TextStyle(color: Colors.blueGrey),
                              children: [
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const LoginPage()),
                                      );
                                    },
                                  text: 'Sign In',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF009688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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