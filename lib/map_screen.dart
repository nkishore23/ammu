import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // For current location
import 'package:permission_handler/permission_handler.dart'; // For permissions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: MapScreen()),
  );
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final LatLng _initialCameraPosition =
      LatLng(13.0827, 80.2707); // Chennai, India
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addInitialMarker();
    _requestLocationPermission();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addInitialMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('initialLocation'),
          position: _initialCameraPosition,
          infoWindow: InfoWindow(title: 'Chennai', snippet: 'Default location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.locationWhenInUse.request();
    if (permission.isGranted) {
      _getCurrentLocation();
    } else if (permission.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
    } else if (permission.isPermanentlyDenied) {
      openAppSettings(); // Go to app settings if permanently denied
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'My Current Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }

  void _onSearchSubmitted(String value) {
    // In a real application, you would use a geocoding API (e.g., Google Places API)
    // to convert the search query into LatLng coordinates.
    // For demonstration, we'll just show a simple snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $value')),
    );
    // Example: If you hardcode a location for "Eiffel Tower"
    // if (value.toLowerCase().contains('eiffel tower')) {
    //   final LatLng eiffelTower = LatLng(48.8584, 2.2945);
    //   mapController?.animateCamera(CameraUpdate.newLatLngZoom(eiffelTower, 15.0));
    //   setState(() {
    //     _markers.add(
    //       Marker(
    //         markerId: MarkerId('eiffelTower'),
    //         position: eiffelTower,
    //         infoWindow: InfoWindow(title: 'Eiffel Tower'),
    //       ),
    //     );
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal, // You can change this
            myLocationEnabled: false, // We'll use a custom button for this
            zoomControlsEnabled: false, // Custom zoom controls if needed
            myLocationButtonEnabled: false, // Custom button
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.0,
            left: 10.0,
            right: 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for places...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(
                                () {}); // To refresh the clear button visibility
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onChanged: (text) {
                  setState(() {}); // To enable/disable the clear button
                },
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          // You can add more UI elements here based on your image,
          // for example, a layers button, directions button, etc.
          // Positioned(
          //   bottom: 20.0,
          //   left: 20.0,
          //   child: FloatingActionButton(
          //     onPressed: () {
          //       // Handle layers button tap
          //     },
          //     backgroundColor: Colors.white,
          //     child: Icon(Icons.layers, color: Colors.blue),
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
