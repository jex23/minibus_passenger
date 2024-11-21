import 'package:flutter/material.dart';

class DraggableSheet extends StatefulWidget {
  final List<int> availableSeats; // List of available seats
  final List<int> occupiedSeats;  // List of occupied seats
  final Function(int) onSeatTapped;  // Callback for seat tap
  final int? seatSelected;  // Currently selected seat

  DraggableSheet({
    required this.availableSeats,
    required this.occupiedSeats,
    required this.onSeatTapped,
    required this.seatSelected,
  });

  @override
  _DraggableSheetState createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text("Driver Seat", style: TextStyle(fontSize: 18)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 10),
                    Text(
                      'Available Seats: ${widget.availableSeats.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Occupied Seats: ${widget.occupiedSeats.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildSeatRow([0], "Driver"),
                SizedBox(height: 20),
                _buildSeatRow([1, 2, null, null, 3]),
                SizedBox(height: 20),
                _buildSeatRow([4, 5, null, null, 6]),
                SizedBox(height: 20),
                _buildSeatRow([7, 8, null, null, null, null]),
                SizedBox(height: 20),
                _buildSeatRow([9, 10, null, null, 11]),
                SizedBox(height: 20),
                _buildSeatRow([12, 13, null, null, 14]),
                SizedBox(height: 20),
                _buildSeatRow([15, 16, null, null, 17]),
                SizedBox(height: 20),
                _buildSeatRow([18, 19, null, null, 20]),
                SizedBox(height: 20),
                _buildSeatRow([21, 22, 23, 24]),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to build a row of seats
  Widget _buildSeatRow(List<int?> seatIndices, [String? label]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(label, style: TextStyle(fontSize: 16)),
          ),
        ...seatIndices.map((index) {
          if (index == null) {
            return SizedBox(width: 30); // Space for an empty seat
          } else {
            bool isAvailable = widget.availableSeats.contains(index);
            bool isOccupied = widget.occupiedSeats.contains(index);
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                onTap: () => widget.onSeatTapped(index), // Call the callback function
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? Colors.red // Color for occupied seats
                        : isAvailable
                        ? Colors.green // Color for available seats
                        : Colors.grey, // Color for seats that are neither available nor occupied
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Center(
                    child: Text(
                      "Seat ${index + 1}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }).toList(),
      ],
    );
  }
}
