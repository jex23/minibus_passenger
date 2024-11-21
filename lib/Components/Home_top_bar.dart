import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  final String user;

  const HomeTopBar({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent, // Set the background color
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome $user to Mini Bus Ride Checker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8), // Add space between the texts
                Text(
                  'Wherever you’re going, let’s get you there.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Image.asset(
              'assets/bus.png', // Ensure the image is placed in the assets directory
              width: 500, // Set the width to 500 px
              fit: BoxFit.contain, // Ensure the image scales properly
            ),
          ),
        ],
      ),
    );
  }
}
