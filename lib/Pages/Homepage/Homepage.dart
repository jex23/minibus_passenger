import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minibus_passenger/Components/Sidemenu.dart'; // Ensure this import is correct
import 'package:minibus_passenger/Components/Home_top_bar.dart'; // Import the HomeTopBar component
import 'package:minibus_passenger/Components/Buttons/BusButtons.dart'; // Import the BusButtons component
import 'LocationSelection.dart'; // Import the LocationSelection page

class Homepage extends StatefulWidget {
  final String uid; // Accept UID as a parameter

  const Homepage({Key? key, required this.uid}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fullName;
  String? _passengerType;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    // Use the passed UID to get the user details from Firestore
    DocumentSnapshot snapshot = await _firestore.collection('Passengers').doc(widget.uid).get();

    if (snapshot.exists) {
      setState(() {
        _fullName = snapshot['fullName'];
        _passengerType = snapshot['passengerType'];
      });
    } else {
      print("User details not found in Firestore");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
          ),
        ),
      ),
      drawer: Sidemenu(uid: widget.uid), // Add the sidebar here
      body: Column(
        children: [
          HomeTopBar(user: _fullName ?? 'User'), // Use the HomeTopBar component
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _fullName == null
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Mini Bus',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20), // Space before the buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space the buttons evenly
                    children: [
                      BusButtons(
                        label: 'Bulan', // Button for Bulan
                        onPressed: () {
                          // Navigate to LocationSelection and pass 'Bulan' as an argument
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelection(
                                bus: 'Bulan',
                                uid: widget.uid, // Pass the UID here
                              ),
                            ),
                          );
                        },
                      ),
                      BusButtons(
                        label: 'Matnog', // Button for Matnog
                        onPressed: () {
                          // Navigate to LocationSelection and pass 'Matnog' as an argument
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelection(
                                bus: 'Matnog',
                                uid: widget.uid, // Pass the UID here
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
