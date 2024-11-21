import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class GeolocationService {
  Future<Position?> getCurrentLocation() async {
    var permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } else {
      return null;
    }
  }

  Future<List<Placemark>> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude).timeout(Duration(seconds: 10));
      return placemarks; // Return the fetched placemarks
    } on TimeoutException catch (e) {
      print("Timeout while fetching address: $e");
      return []; // Return an empty list instead of null
    } catch (e) {
      print("Error fetching address: $e");
      return []; // Return an empty list instead of null
    }
  }

  Future<Position?> getInitialPosition() async {
    Position? currentPosition = await getCurrentLocation();
    return currentPosition;
  }

  void listenToLocationChanges(Function(String) onLocationUpdate) {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      if (position != null) {
        // Fetch the new address based on the updated position
        List<Placemark> placemarks = await getAddressFromLatLng(position);
        if (placemarks.isNotEmpty) {
          String address = '${placemarks.first.name}, ${placemarks.first.locality}';
          onLocationUpdate(address); // Call the callback to update the UI
        } else {
          onLocationUpdate('Could not find address');
        }
      }
    });
  }
}
