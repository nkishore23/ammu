import 'package:flutter/material.dart';
import 'bluetooth_scan_screen.dart';

void main() async {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddDeviceScreen(),
    ),
  );
}

class AddDeviceScreen extends StatelessWidget {
  const AddDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Blue curved background
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: CurvedBackgroundPainter(),
            ),

            // Content
            Column(
              children: [
                // Header with back button and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Add your device',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Bluetooth icon with circular background and glow effect
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    size: 60,
                    color: Color(0xFF1E3A8A),
                  ),
                ),

                const Spacer(),

                // Bottom content section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                    child: Column(
                      children: [
                        // Instructions text
                        const Text(
                          'Turn on Bluetooth connection settings in your smart watch and make sure your Device is close to your phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF374151),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Pair Device button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BluetoothScanScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Pair Device',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the exact curved wave background matching the original image
class CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint =
        Paint()
          ..color = const Color(0xFF1E3A8A)
          ..style = PaintingStyle.fill;

    final path = Path();

    // Create the exact shape from the reference image
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.55);

    // Create the smooth flowing wave exactly like in the image
    // First part of the wave - gentle curve down and left
    path.cubicTo(
      size.width * 0.85, // Control point 1 X
      size.height * 0.58, // Control point 1 Y
      size.width * 0.65, // Control point 2 X
      size.height * 0.62, // Control point 2 Y
      size.width * 0.4, // End point X
      size.height * 0.64, // End point Y
    );

    // Second part of the wave - continues the flow to the left edge
    path.cubicTo(
      size.width * 0.2, // Control point 1 X
      size.height * 0.66, // Control point 1 Y
      size.width * 0.08, // Control point 2 X
      size.height * 0.70, // Control point 2 Y
      0, // End point X (left edge)
      size.height * 0.75, // End point Y
    );

    // Close the path
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, bluePaint);

    // Add the bottom blue section exactly as shown in the image
    final bottomRect = Rect.fromLTWH(0, size.height - 100, size.width, 100);
    canvas.drawRect(bottomRect, bluePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
