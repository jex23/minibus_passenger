import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPage extends StatefulWidget {
  final String uid;

  EditPage({Key? key, required this.uid}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fullName;
  String? _email;
  String? _passengerType;

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load the user data from Firestore
  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await _firestore.collection('Passengers').doc(widget.uid).get();
    setState(() {
      _fullName = userDoc['fullName'];
      _email = userDoc['email'];
      _passengerType = userDoc['passengerType'];
      _isLoading = false;
    });
  }

  // Save the profile changes (Full Name, Email, Passenger Type)
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _firestore.collection('Passengers').doc(widget.uid).update({
        'fullName': _fullName,
        'email': _email,
        'passengerType': _passengerType,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      setState(() {
        _isEditing = false; // Return to view mode
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Full Name Field
                TextFormField(
                  initialValue: _fullName,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _fullName = value;
                  },
                ),
                SizedBox(height: 20),

                // Email Field
                TextFormField(
                  initialValue: _email,
                  enabled: false, // Email should be non-editable
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Passenger Type Dropdown
                DropdownButtonFormField<String>(
                  value: _passengerType,
                  decoration: InputDecoration(
                    labelText: 'Passenger Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Senior', 'Regular', 'Student', 'PWD']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: _isEditing
                      ? (value) {
                    setState(() {
                      _passengerType = value;
                    });
                  }
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a passenger type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Edit and Save Button
                _isEditing
                    ? ElevatedButton(
                  onPressed: _saveChanges,
                  child: Text('Update Profile'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent, // Using backgroundColor
                  ),
                )
                    : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.green, // Using backgroundColor
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
