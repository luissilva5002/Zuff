import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:zuff/utils.dart';
import 'auth/login.dart';
import 'firebase_options.dart';
import 'home.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize shared prefs
  await SharedPreferences.getInstance();

  runApp(MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Utils.messengerKey,
      home: const AuthStreamBuilder(),
    );
  }
}

class AuthStreamBuilder extends StatelessWidget {
  const AuthStreamBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()),);
        } else if (snapshot.hasData) {
          return const Home();
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        } else {
          return const LoginPage();
        }
      },
    );
  }
}