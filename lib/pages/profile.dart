import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String imageUrl = 'https://cdn.iconscout.com/icon/free/png-256/free-flutter-2038877-1720090.png?f=webp';
  String name = 'User123';
  String email = 'jonh.doe@gmail.com';
  String creationDate = '${DateTime.now()}';

  User? currentUser;

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String? savedName = prefs.getString('name');
      String? savedEmail = prefs.getString('email');
      String? savedCreationDate = prefs.getString('creationDate');

      if (savedName != null && savedEmail != null && savedCreationDate != null) {
        setState(() {
          name = savedName;
          email = savedEmail;
          creationDate = savedCreationDate;
        });
      } else {
        DocumentSnapshot userInfo = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userInfo.exists) {
          setState(() {
            name = userInfo['display_name'] ?? 'User123';
            email = userInfo['email'] ?? 'jonh.doe@gmail.com';
            creationDate = userInfo['created_time'] ?? '${DateTime.now()}';
          });

          await prefs.setString('name', name);
          await prefs.setString('email', email);
          await prefs.setString('creationDate', creationDate);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF011526),
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const surelogout(),
              );
            },
          ),
        ],
      ),
      /*
      body:
      SafeArea(
        child: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF011526),
                Color(0xFF012E40),
                Color(0xFF025959),
                Color(0xFF02735E),
                Color(0xFF038C65),
              ],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildProfileAvatar(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 25)),
                    ],
                  ),
                  const Divider(color: Colors.transparent),
                  const Divider(color: Colors.transparent),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'ACCOUNT INFO',
                        textAlign: TextAlign.left,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Email:', textAlign: TextAlign.left),
                          Text(email, textAlign: TextAlign.right),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Created', textAlign: TextAlign.left),
                          Text(creationDate, textAlign: TextAlign.right),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {},
                                  child: Text(
                                    'Help & Support',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: null),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

       */
    );
  }

  Center buildProfileAvatar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Icon(
            Icons.person, // User icon
            size: 100,
            color: Theme.of(context).colorScheme.surface, // Icon color
          ),
        ),
      ),
    );
  }
}

class surelogout extends StatefulWidget {
  const surelogout({super.key});

  @override
  State<surelogout> createState() => _surelogoutState();
}

class _surelogoutState extends State<surelogout> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmation'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          ),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
          },
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}