import 'package:flutter/material.dart';

class CheckForPickup extends StatelessWidget {
  final String collectionId;

  CheckForPickup({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check For Pickup'),
      ),
      body: Center(
        child: Text(
          'Collection ID: $collectionId',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
