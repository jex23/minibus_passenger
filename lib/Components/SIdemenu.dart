import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minibus_passenger/Pages/LoginSignup/Login.dart'; // Import the Login Page
import 'package:minibus_passenger/Pages/Homepage/edit.dart'; // Import the Login Page

class Sidemenu extends StatelessWidget {
  final String uid;

  Sidemenu({Key? key, required this.uid}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getUserName() async {
    DocumentSnapshot userDoc = await _firestore.collection('Passengers').doc(uid).get();
    return userDoc['fullName'] ?? 'User';
  }

  Future<String> _getUserEmail() async {
    User? user = _auth.currentUser; // Get the current user
    return user?.email ?? 'user@example.com'; // Return the email or a default value
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    // Navigate back to the Login page using MaterialPageRoute
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(), // Ensure LoginPage is imported
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: _getUserName(),
        builder: (context, snapshot) {
          String userName = snapshot.data ?? 'Loading...';
          return FutureBuilder<String>(
            future: _getUserEmail(), // Fetch the user's email
            builder: (context, emailSnapshot) {
              String userEmail = emailSnapshot.data ?? 'Loading...';
              return ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent, // Set the desired color here
                    ),
                    accountName: Text(userName),
                    accountEmail: Text(userEmail), // Display the user's email
                    currentAccountPicture: Image.asset(
                      'assets/bus.png', // Replace with bus.png
                      width: 70,
                      height: 70,
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Info'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditPage(uid: uid)),
                        );
                      },

                    ),
                  ),
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      onTap: () => _logout(context),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
