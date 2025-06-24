import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

// The GpsTrackingScreen, designed to be integrated as a tab within a parent Scaffold.
// Its AppBar and BottomNavigationBar are removed as they are managed by the parent HomeScreen.
class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  String _selectedUser = 'Rose';
  GoogleMapController? mapController;
  bool _isMapReady = false; // Tracks if the map is initialized

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Chennai, India - example location
    zoom: 13.0,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Initializes the screen by requesting permissions and adding markers
  Future<void> _initializeScreen() async {
    try {
      await _requestLocationPermissions();
      _addInitialMarkers();
    } catch (e) {
      // Catch any errors during initialization and show a snackbar
      print('Error initializing GPS screen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing GPS: ${e.toString()}')),
        );
      }
    }
  }

  // Requests location permissions from the user
  Future<void> _requestLocationPermissions() async {
    try {
      // Check if location services are enabled on the device
      bool serviceEnabled =
          await Permission.locationWhenInUse.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        print('Location services are disabled. Prompting user to enable.');
        // Show a message and potentially open app settings if location is disabled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location services are disabled. Please enable them in settings.')),
          );
        }
        await openAppSettings(); // Opens app settings for the user
        return;
      }

      // Request foreground location permission
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
        if (status.isDenied) {
          print('Location permission denied by user.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Location permission denied. Map functionality may be limited.')),
            );
          }
          return;
        }
      }
      if (status.isPermanentlyDenied) {
        print(
            'Location permission permanently denied. Open settings to grant.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permission permanently denied. Please enable in app settings.')),
          );
        }
        await openAppSettings();
        return;
      }

      if (status.isGranted) {
        print('Location permission granted.');
      }
    } catch (e) {
      print('Error requesting location permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error requesting location permissions: ${e.toString()}')),
        );
      }
    }
  }

  // Adds initial static markers to the map
  void _addInitialMarkers() {
    if (!mounted)
      return; // Ensure widget is still mounted before calling setState

    setState(() {
      _markers.clear(); // Clear existing markers before adding
      _markers.addAll([
        Marker(
          markerId: const MarkerId('policeStation'),
          position: const LatLng(13.0850, 80.2650),
          infoWindow: const InfoWindow(title: 'Police Station'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('hmSchool'),
          position: const LatLng(13.0900, 80.2750),
          infoWindow: const InfoWindow(title: 'HM School'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('vmSchool'),
          position: const LatLng(13.0750, 80.2700),
          infoWindow: const InfoWindow(title: 'VM School'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('ngo'),
          position: const LatLng(13.0700, 80.2800),
          infoWindow: const InfoWindow(title: 'NGO'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      ]);
    });
  }

  // Callback when the Google Map is created
  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;

    mapController = controller;
    setState(() {
      _isMapReady = true; // Mark map as ready
    });
    print('Google Map created successfully');
  }

  @override
  void dispose() {
    mapController
        ?.dispose(); // Dispose of the map controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This screen is now a Column, as its parent (HomeScreen's IndexedStack)
    // provides the Scaffold, AppBar, and BottomNavigationBar.
    return Column(
      children: [
        // --- User Selection and Add Button ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserSelectionChip('Rose'),
              const SizedBox(width: 10),
              _buildUserSelectionChip('Jyoti'),
              const Spacer(), // Pushes "Add" button to the right
              ElevatedButton.icon(
                onPressed: () {
                  print('Add button tapped');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Add functionality coming soon!')),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF0D47A1), // Dark blue button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),

        // --- Map View with error handling and loading indicator ---
        Expanded(
          flex: 2, // Gives more space to the map
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildMapWidget(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- Recent Activity Section Header ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333), // Dark grey
                ),
              ),
              TextButton(
                onPressed: () {
                  print('See all tapped');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('See all functionality coming soon!')),
                    );
                  }
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF0D47A1), // Dark blue
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // --- Recent Activity List ---
        Expanded(
          flex: 1, // Gives less space to the list than the map
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: const [
              ActivityCard(
                imagePath:
                    'https://placehold.co/60x60/ADD8E6/000000?text=TC', // Placeholder image
                title: 'Tuition Center',
                time: '20 minutes ago',
                user: 'Rose',
              ),
              ActivityCard(
                imagePath:
                    'https://placehold.co/60x60/C0C0C0/000000?text=LB', // Placeholder image
                title: 'Library',
                time: '3 Hours ago',
                user: 'Jyoti',
              ),
              ActivityCard(
                imagePath:
                    'https://placehold.co/60x60/DDA0DD/000000?text=HM', // Placeholder image
                title: 'Home',
                time: '6 Hours ago',
                user: 'Jyoti',
              ),
              // Add more ActivityCard widgets here as needed
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget to build the Google Map, showing a loading indicator if not ready
  Widget _buildMapWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled:
                false, // Set to true if you want the blue dot for current location
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: true,
            onCameraMove: (CameraPosition position) {
              // Handle camera movement if needed
            },
            onTap: (LatLng position) {
              print(
                  'Map tapped at: ${position.latitude}, ${position.longitude}');
            },
          ),
          // Show a loading indicator until the map is ready
          if (!_isMapReady)
            Container(
              color: Colors.grey.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for user selection chips (radio buttons)
  Widget _buildUserSelectionChip(String user) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUser = user;
        });
        print('Selected user: $user');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedUser == user
              ? const Color(0xFFE0E7FA) // Light blue for selected
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedUser == user
                ? const Color(0xFF0D47A1)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _selectedUser == user
                    ? const Color(0xFF0D47A1)
                    : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user,
              style: TextStyle(
                color: _selectedUser == user
                    ? const Color(0xFF0D47A1)
                    : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget for Recent Activity Cards
class ActivityCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String time;
  final String user;

  const ActivityCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.time,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              user,
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
