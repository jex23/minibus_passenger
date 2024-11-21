import 'package:flutter/material.dart';

class BusButtons extends StatelessWidget {
  final String label; // Dynamic label for the button
  final VoidCallback onPressed; // Callback for button press

  // Declare the path to bus2.png
  static const String busImagePath = 'assets/bus2.png';

  const BusButtons({
    Key? key,
    required this.label,
    required this.onPressed, // Add this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // Trigger the callback when the button is tapped
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[300], // Circle color
              shape: BoxShape.circle, // Make it circular
            ),
            child: CircleAvatar(
              radius: 50, // Adjust the radius as needed
              backgroundColor: Colors.blue[100], // Background color for the CircleAvatar
              child: ClipOval(
                child: Image.asset(
                  busImagePath, // Use the declared path here
                  fit: BoxFit.cover, // Resize the image to cover the CircleAvatar
                  width: 90, // Adjust width according to your needs
                  height: 90, // Adjust height according to your needs
                ),
              ),
            ),
          ),
          SizedBox(height: 8), // Space between CircleAvatar and label
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
