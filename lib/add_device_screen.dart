import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Keep if used elsewhere, not directly in this screen
import 'smsaddonscreen.dart'; // Import SMS Services Screen
import 'bluetooth_manager.dart'; // Assume this file exists and manages Bluetooth logic

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate BluetoothManager. If this class holds significant state or
    // requires a specific lifecycle, consider providing it via a Provider package
    // (e.g., provider, flutter_bloc) for better state management.
    final bluetoothManager = BluetoothManager();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top section with wave clipper and Bluetooth icon
          _buildTopSection(context),
          // Bottom section with instructions and pair button
          _buildBottomSection(context),
        ],
      ),
      // Consistent bottom navigation bar placeholder
      bottomNavigationBar: Container(color: Colors.white, height: 50),
    );
  }

  /// Builds the top section with the wave clipper and Bluetooth icon.
  Widget _buildTopSection(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const BottomWaveClipper(), // Added const
              child: Container(color: const Color(0xFF00224C)), // Added const
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 20), // Added const
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0), // Added const
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        // Added const
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Expanded(
                      // Added const
                      child: Text(
                        'Add your device',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          // Added const
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20), // Added const
                  ],
                ),
              ),
              const SizedBox(height: 100), // Added const
              _buildBluetoothIcon(), // Extracted widget for the Bluetooth icon
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the circular Bluetooth icon.
  Widget _buildBluetoothIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        // Removed const due to dynamic boxShadow
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        // Added const
        Icons.bluetooth,
        color: Color(0xFF00224C),
        size: 60,
      ),
    );
  }

  /// Builds the bottom section with instructions and the "Pair Device" button.
  Widget _buildBottomSection(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0), // Added const
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              // Added const
              'Turn on Bluetooth connection settings\n'
              'in your smart watch and make sure your\n'
              'Device is close to your phone',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16), // Removed const due to dynamic color
            ),
            const SizedBox(height: 40), // Added const
            ElevatedButton(
              onPressed: () {
                // Navigate to the SMS Services Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SmsAddonServicesScreen(), // Added const
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                // Removed const due to dynamic backgroundColor
                backgroundColor: const Color(0xFF00224C), // Added const
                minimumSize: const Size(double.infinity, 50), // Added const
                shape: RoundedRectangleBorder(
                  // Removed const due to dynamic borderRadius
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                // Added const
                'Pair Device',
                style: TextStyle(
                  // Removed const due to dynamic color
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Clipper to create a bottom wave effect for a container.
class BottomWaveClipper extends CustomClipper<Path> {
  const BottomWaveClipper(); // Added const constructor

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85,
      size.width * 0.5,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.65,
      0,
      size.height * 0.75,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
