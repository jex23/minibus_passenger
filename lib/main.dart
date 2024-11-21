  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:minibus_passenger/Pages/LoginSignup/Login.dart'; // Import the Login page

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // Initialize Firebase
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: LoginPage(), // Route to the login page
      );
    }
  }
