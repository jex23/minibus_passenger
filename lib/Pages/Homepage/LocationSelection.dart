import 'package:minibus_passenger/Pages/Homepage/mapHomepage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minibus_passenger/Components/Sidemenu.dart';

class LocationSelection extends StatefulWidget {
  final String bus;
  final String uid;

  const LocationSelection({Key? key, required this.bus, required this.uid})
      : super(key: key);

  @override
  _LocationSelectionState createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  String? selectedStartLocation;
  String? selectedEndLocation;
  List<String> startLocations = [];
  List<String> endLocations = [];
  Map<String, String> locationKmMap = {};
  double farePerKm = 0.0;
  double first4KmPrice = 0.0;
  String? passengerType;
  bool isDiscounted = false;

  @override
  void initState() {
    super.initState();
    _loadPassengerData();
    _loadLocations();
    _loadFareData();
  }

  Future<void> _loadPassengerData() async {
    DocumentSnapshot passengerDoc = await FirebaseFirestore.instance
        .collection('Passengers')
        .doc(widget.uid)
        .get();

    if (passengerDoc.exists) {
      setState(() {
        passengerType = passengerDoc['passengerType'] as String?;
        isDiscounted =
            ["Student", "Senior", "PWD", "Pregnant"].contains(passengerType);
      });
    }
  }

  void _loadFareData() async {
    DocumentSnapshot fareDoc = await FirebaseFirestore.instance
        .collection('fare_matrix')
        .doc('fare_per_km')
        .get();

    setState(() {
      farePerKm = (fareDoc['farePerKm'] as num).toDouble();
      first4KmPrice = (fareDoc['first_4km_price'] as num).toDouble();
    });
  }

  void _loadLocations() async {
    startLocations.clear();
    endLocations.clear();
    locationKmMap.clear();

    String busDocument = widget.bus;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('fare_matrix')
        .doc(busDocument)
        .collection('distances')
        .get();

    setState(() {
      for (var doc in snapshot.docs) {
        String location = doc['Location'] as String? ?? '';  // Default empty string if null
        String km = doc['Km']?.toString() ?? '0';  // Default '0' if null
        if (location.isNotEmpty) {
          startLocations.add(location);
          endLocations.add(location);
          locationKmMap[location] = km;
        }
      }
    });
  }

  double _calculateDistance() {
    if (selectedStartLocation != null && selectedEndLocation != null) {
      final startKm =
          double.tryParse(locationKmMap[selectedStartLocation] ?? '0') ?? 0.0;
      final endKm =
          double.tryParse(locationKmMap[selectedEndLocation] ?? '0') ?? 0.0;
      return (endKm - startKm).abs();
    }
    return 0.0;
  }

  double _calculateFare(double distance) {
    double baseFare;
    if (distance <= 4) {
      baseFare = first4KmPrice;
    } else {
      baseFare = first4KmPrice + (distance - 4) * farePerKm;
    }
    return isDiscounted ? baseFare * 0.8 : baseFare;
  }

  // Function to update pickup status in the "Passengers" collection
  Future<void> _updatePickupStatusToYes(String passengerId) async {
    try {
      // Reference the Passengers collection
      CollectionReference passengers = FirebaseFirestore.instance.collection('Passengers');

      // Update the pickup_status for the passenger
      await passengers.doc(passengerId).update({
        'pickup_status': 'yes', // Set the pickup_status to "yes"
      });

      print('Passenger pickup_status updated to "yes"');
    } catch (e) {
      print('Error updating pickup_status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double distance = _calculateDistance();
    double fare = _calculateFare(distance);
    String destination =
        "${selectedStartLocation ?? ''} to ${selectedEndLocation ?? ''}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Available ${widget.bus} Buses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Sidemenu(uid: widget.uid),
      body: Column(
        children: [
          // Fare and location selection UI
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start and end location dropdowns
                DropdownButtonFormField<String>(
                  value: selectedStartLocation,
                  hint: Text('Select Start Location'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: startLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text('$location (${locationKmMap[location]} Km)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStartLocation = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedEndLocation,
                  hint: Text('Select End Location'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: endLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text('$location (${locationKmMap[location]} Km)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEndLocation = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance: ${distance.toString()} Km',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      'Fare: ₱${fare.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                if (isDiscounted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '20% Discount Applied!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent),
                    ),
                  ),
                Text(
                  'Passenger Type: ${passengerType ?? "Unknown"}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          // Bus list and card click event
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Conductors')
                  .where('busType', isEqualTo: widget.bus)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text('No buses available for ${widget.bus}'));
                }
                final buses = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final busData = buses[index].data() as Map<String, dynamic>;
                    final busNumber = busData['busNumber'] ?? 'Unknown';
                    final selectedRoute = busData['selectedRoute'] ?? 'No route available';
                    final address = busData['address'] ?? 'Address not available';
                    final availableSeats = busData['availableSeats'] as List? ?? [];
                    final occupiedSeats = busData['occupiedSeats'] as List? ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            busNumber.toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        title: Text('Route: $selectedRoute'),
                        subtitle: Text('Address: $address'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Available: ${availableSeats.length}'),
                            Text('Occupied: ${occupiedSeats.length}'),
                          ],
                        ),
                        onTap: () async {
                          if (selectedStartLocation == null || selectedEndLocation == null) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Incomplete Location Selection'),
                                  content: Text(
                                      'Please select both start and end locations before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            final busId = buses[index].id; // Get the bus document ID
                            String forPickUpDocId;

                            // Query the For_Pick_Up collection to check if the uid exists
                            final querySnapshot = await FirebaseFirestore.instance
                                .collection('For_Pick_Up')
                                .where('uid', isEqualTo: widget.uid)
                                .limit(1)
                                .get();

                            if (querySnapshot.docs.isNotEmpty) {
                              // Document exists, so update it and retrieve its ID
                              final docId = querySnapshot.docs.first.id;
                              forPickUpDocId = docId; // Save the existing document ID
                              await FirebaseFirestore.instance
                                  .collection('For_Pick_Up')
                                  .doc(docId)
                                  .update({
                                'check': "False",
                                'bus': widget.bus,
                                'fare': fare,
                                'destination': destination,
                                'distance': distance,
                                'busId': busId,
                                'busNumber': busNumber,
                                'status': "Waiting",
                              });
                            } else {
                              // Document does not exist, so create a new one and retrieve its ID
                              final newDocRef = await FirebaseFirestore.instance
                                  .collection('For_Pick_Up')
                                  .add({
                                'check': "False",
                                'uid': widget.uid,
                                'bus': widget.bus,
                                'fare': fare,
                                'destination': destination,
                                'distance': distance,
                                'busId': busId,
                                'busNumber': busNumber,
                                'status': "Waiting",
                              });
                              forPickUpDocId = newDocRef.id; // Save the new document ID
                            }

                            // After updating the "For_Pick_Up" collection, update the pickup_status in the "Passengers" collection
                            await _updatePickupStatusToYes(widget.uid); // Update pickup_status to "yes" for the selected passenger

                            // Navigate to the MapHomepage, passing forPickUpDocId as a parameter
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapHomepage(
                                  uid: widget.uid,
                                  bus: widget.bus,
                                  fare: fare,
                                  destination: destination,
                                  distance: distance,
                                  busId: busId,
                                  busNumber: busNumber,
                                  selectedRoute: selectedRoute,
                                  forPickUpDocId: forPickUpDocId, // Pass the document ID
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
