import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:minibus_passenger/services/geolocation_service.dart';
import 'package:minibus_passenger/Components/Sidemenu.dart';
import 'package:minibus_passenger/Pages/Homepage/LocationSelection.dart';
import 'package:minibus_passenger/Components/draggable_sheet.dart';
import 'package:minibus_passenger/Pages/Homepage/messages.dart';

class MapHomepage extends StatefulWidget {
  final String uid;
  final String bus;
  final double fare;
  final String destination;
  final double distance;
  final String busId;
  final int busNumber;
  final String selectedRoute;
  final String forPickUpDocId;


  const MapHomepage({
    Key? key,
    required this.uid,
    required this.bus,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.busId,
    required this.busNumber,
    required this.selectedRoute,
    required this.forPickUpDocId,

  }) : super(key: key);

  @override
  _MapHomepageState createState() => _MapHomepageState();
}

class _MapHomepageState extends State<MapHomepage> {
  GoogleMapController? mapController;
  BitmapDescriptor? userMarkerIcon;
  BitmapDescriptor? busMarkerIcon;
  Marker? userMarker;
  Map<String, Marker> conductorMarkers = {}; // Store multiple conductor markers
  final GeolocationService _geolocationService = GeolocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? status = "waiting";
  List<int> availableSeats = [];
  List<int> occupiedSeats = [];
  int? _seatSelected;
  late CollectionReference _messagesRef;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _initializeUserLocation();
    _checkLocationPermission();
    _messagesRef = _firestore.collection('Message');
    _listenToStatusUpdates();
    _listenToSeatUpdates();
    _listenToConductorLocationUpdates();
  }

  Future<void> _loadCustomMarkers() async {
    // Load custom icons for user and bus markers
    userMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'images/arm-up.png',
    );
    busMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'images/bus2.png',
    );
  }

  Future<void> _initializeUserLocation() async {
    Position? position = await _geolocationService.getCurrentLocation();
    if (position != null) {
      _updateUserMarker(position.latitude, position.longitude);
      mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
      _updateLocationInFirestore(position.latitude, position.longitude);
    }
  }

  Future<void> _updateLocationInFirestore(double latitude, double longitude) async {
    await _firestore.collection('Passengers').doc(widget.uid).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void _updateUserMarker(double latitude, double longitude) {
    if (userMarkerIcon == null) return;

    final newUserMarker = Marker(
      markerId: MarkerId('userLocation'),
      position: LatLng(latitude, longitude),
      icon: userMarkerIcon!,
      infoWindow: InfoWindow(title: "Your Location"),
    );

    setState(() {
      userMarker = newUserMarker;
    });
  }

  void _listenToStatusUpdates() {
    _firestore
        .collection('For_Pick_Up')
        .doc(widget.forPickUpDocId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          status = data?['status'];
        });

        if (status == 'Denied') {
          _messagesRef
              .where('uid', isEqualTo: widget.uid)
              .where('busId', isEqualTo: widget.busId)
              .get()
              .then((querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              querySnapshot.docs.first.reference.delete();
            }
          });

          await _firestore.collection('Passengers').doc(widget.uid).update({
            'pickup_status': 'no',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Your pickup has been canceled')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LocationSelection(bus: widget.bus, uid: widget.uid),
            ),
          );
        }
      } else {
        setState(() {
          status = null;
        });
      }
    });
  }

  void _listenToSeatUpdates() {
    _firestore
        .collection('Conductors')
        .doc(widget.busId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          setState(() {
            availableSeats = List<int>.from(data['availableSeats'] ?? []);
            occupiedSeats = List<int>.from(data['occupiedSeats'] ?? []);
          });
        }
      }
    });
  }

  void _listenToConductorLocationUpdates() {
    // Listen to real-time updates for all conductors
    _firestore.collection('Conductors').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          conductorMarkers.clear(); // Clear previous markers
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['busLocation'] != null) {
              final latitude = data['busLocation']['latitude'];
              final longitude = data['busLocation']['longitude'];
              final busNumber = data['busNumber'];
              final busType = data['busType'];
              final selectedRoute = data['selectedRoute'];

              // Create or update marker for each conductor
              final busMarker = Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(latitude, longitude),
                icon: busMarkerIcon!,
                infoWindow: InfoWindow(
                  title: "$busType $busNumber",
                  snippet: selectedRoute,
                ),
              );

              conductorMarkers[doc.id] = busMarker; // Store each bus marker in the map
            }
          }
        });
      }
    });
  }

  void _checkLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _initializeUserLocation();
      _listenToLocationChanges();
    }
  }

  void _listenToLocationChanges() {
    _geolocationService.listenToLocationChanges((String address) async {
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition != null) {
        _updateUserMarker(currentPosition.latitude, currentPosition.longitude);
        _updateLocationInFirestore(currentPosition.latitude, currentPosition.longitude);
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _initializeUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.bus} Route Bus no.${widget.busNumber}'),
      ),
      drawer: Sidemenu(uid: widget.uid),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(12.828366237169552, 123.90496115151824),
              zoom: 16,
            ),
            markers: {
              if (userMarker != null) userMarker!,
              ...conductorMarkers.values, // Add all conductor markers
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fare: \₱${widget.fare.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Distance: ${widget.distance.toStringAsFixed(2)} km',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Route: ${widget.selectedRoute}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Destination: ${widget.destination}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    SizedBox(width: 10),
                    Text(
                      'Status: $status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _firestore.collection('Passengers').doc(widget.uid).update({
                            'pickup_status': 'no',
                          });

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelection(uid: widget.uid, bus: widget.bus),
                            ),
                          );
                        },
                        child: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          DraggableSheet(
            availableSeats: availableSeats,
            occupiedSeats: occupiedSeats,
            onSeatTapped: (seatNumber) {},
            seatSelected: _seatSelected,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {},
            child: Icon(Icons.my_location),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Messages(uid: widget.uid, busId: widget.busId),
                ),
              );
            },
            child: Icon(Icons.message),
          ),
        ],
      ),
    );
  }
}
