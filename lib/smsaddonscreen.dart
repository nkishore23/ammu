import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_manager.dart'; // Import the new manager
import 'deviceservice.dart'; // Assume this file exists for device saving
import 'home_screen.dart'; // Import the HomeScreen

// The main function for running the app.
void main() async {
  // Ensure Flutter widgets are initialized before running the app,
  // especially important for plugins like FlutterBluePlus.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      // Start the app with the SMS Addon Services Screen
      home: SmsAddonServicesScreen(),
    ),
  );
}

/// A screen for managing SMS add-on services and pairing a GPS smart watch/chip.
class SmsAddonServicesScreen extends StatefulWidget {
  const SmsAddonServicesScreen({super.key});

  @override
  State<SmsAddonServicesScreen> createState() => _SmsAddonServicesScreenState();
}

class _SmsAddonServicesScreenState extends State<SmsAddonServicesScreen>
    with TickerProviderStateMixin {
  // Controller for the pulsing animation of the "Pair" button.
  late final AnimationController _animationController;

  // Instance of the BluetoothManager to handle Bluetooth operations.
  late final BluetoothManager _bluetoothManager;

  // Flag to prevent multiple concurrent actions (e.g., multiple dialogs).
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    // Initialize BluetoothManager. This should ideally be a singleton or
    // provided via a state management solution (e.g., Provider) to avoid recreating it.
    _bluetoothManager = BluetoothManager();

    // Initialize animation controller for the ripple effect.
    // The duration dictates how fast one full pulse cycle completes.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // A 2-second cycle for each ripple
    )..repeat(); // Make the animation repeat indefinitely.
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Dispose animation controller to prevent memory leaks.
    _bluetoothManager
        .dispose(); // Dispose BluetoothManager to clean up streams/resources.
    super.dispose();
  }

  /// Handles the entire pairing process, from showing the scan dialog
  /// to navigating to the home screen upon successful connection.
  Future<void> _handlePairingProcess() async {
    // Prevent multiple calls if an action is already in progress.
    if (_isActionInProgress) return;

    setState(() {
      _isActionInProgress = true; // Set flag to indicate action in progress.
      _animationController
          .stop(); // Stop the ripple animation when the dialog opens.
    });

    // Show the scan and connect dialog. This dialog will return the connected
    // BluetoothDevice if successful, or null if cancelled/failed.
    final BluetoothDevice? connectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      barrierDismissible: false, // Prevents closing dialog by tapping outside.
      builder: (context) => ScanAndConnectDialog(
          bluetoothManager:
              _bluetoothManager), // Pass the manager to the dialog.
    );

    // Check if a device was successfully connected and if the widget is still mounted.
    if (connectedDevice != null && mounted) {
      // Save the connected device information.
      // Assuming DeviceService.instance is a singleton that handles storage.
      DeviceService.instance.saveDevice(connectedDevice);

      // Navigate to the HomeScreen and remove all previous routes from the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const HomeScreen()), // Added const
        (Route<dynamic> route) => false,
      );
    } else {
      // If no device connected or dialog was dismissed, reset UI state.
      if (mounted) {
        setState(() {
          _isActionInProgress = false; // Reset action flag.
          _animationController.repeat(); // Restart the ripple animation.
        });
      }
    }
  }

  /// Builds a single ripple circle for the "Pair" button animation.
  /// [animationOffset] determines the starting point (delay) of this specific
  /// ripple within the overall animation cycle (0.0 to 1.0).
  Widget _buildRipple(double animationOffset) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Calculate the current animation progress for this specific ripple,
        // accounting for its staggered start using modulo to wrap around.
        // This ensures a continuous loop of ripples.
        final double normalizedTime =
            (_animationController.value + animationOffset) % 1.0;

        // Apply an easing curve (easeInOutQuad) for a more pronounced and
        // visually impactful expansion and fade-out effect.
        final double easedProgress =
            Curves.easeInOutQuad.transform(normalizedTime);

        // Radius expands significantly from a slightly larger than button size to a large max.
        // This gives a strong outward "wave" impression.
        const double baseButtonRadius = 65.0;
        const double maxRippleRadius =
            180.0; // The max size a ripple will reach
        // Current radius starts from the button's edge and expands.
        final double currentRadius = baseButtonRadius +
            (maxRippleRadius - baseButtonRadius) * easedProgress;

        // Opacity fades from clearly visible to fully transparent.
        // A sharper initial opacity makes the wave more noticeable.
        const double startOpacity =
            0.6; // Start with higher opacity for clear visibility
        const double endOpacity = 0.0;
        final double opacity =
            startOpacity + (endOpacity - startOpacity) * easedProgress;

        // Clamp opacity to ensure it's within 0.0 to 1.0, preventing errors.
        final double clampedOpacity = opacity.clamp(0.0, 1.0);

        return CircleAvatar(
          radius: currentRadius,
          // Use the main button's color with the calculated fading opacity.
          backgroundColor: const Color(0xFF0d47a1)
              .withOpacity(clampedOpacity), // Added const
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF003366), // Matching the blue from mockup
        title: Text(
          'SMS Add on Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2), // Added const
            const Text(
              // Added const
              'Tap on pair Button to pair\nGPS Smart Watch / Chip',
              textAlign: TextAlign.center,
              style: TextStyle(
                // Added const
                fontSize: 18,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const Spacer(flex: 1), // Added const
            GestureDetector(
              onTap: _isActionInProgress
                  ? null
                  : _handlePairingProcess, // Disable tap if action is in progress
              child: SizedBox(
                width: 200, // Max width for the entire animation area
                height: 200, // Max height for the entire animation area
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Only show ripples if no action is in progress.
                        // The `animationOffset` values create a staggered start for each ripple,
                        // giving the "waving" or "pulse" effect of multiple expanding circles.
                        if (!_isActionInProgress) ...[
                          _buildRipple(0.0), // First ripple starts immediately
                          _buildRipple(
                              0.25), // Second ripple starts after 25% of the cycle
                          _buildRipple(
                              0.50), // Third ripple starts after 50% of the cycle
                          _buildRipple(
                              0.75), // Fourth ripple starts after 75% of the cycle
                        ],
                        child!, // The main "Pair" button itself (passed as child for efficiency)
                      ],
                    );
                  },
                  child: CircleAvatar(
                    // This child (the central button) won't rebuild with animation,
                    // only its parent Stack.
                    radius: 65,
                    backgroundColor: const Color(0xFF0d47a1), // Added const
                    child: _isActionInProgress
                        ? const CircularProgressIndicator(
                            // Added const
                            valueColor: AlwaysStoppedAnimation<Color>(
                              // Added const
                              Colors.white,
                            ),
                          )
                        : const Text(
                            // Added const
                            'Pair',
                            style: TextStyle(
                              // Added const
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3), // Added const
          ],
        ),
      ),
    );
  }
}

// --- scan_and_connect_dialog.dart (or part of main.dart) ---
/// A dialog widget that handles scanning for Bluetooth devices and connecting to one.
class ScanAndConnectDialog extends StatefulWidget {
  final BluetoothManager bluetoothManager;
  const ScanAndConnectDialog({required this.bluetoothManager, super.key});

  @override
  State<ScanAndConnectDialog> createState() => _ScanAndConnectDialogState();
}

class _ScanAndConnectDialogState extends State<ScanAndConnectDialog> {
  // A local flag to prevent multiple connection attempts while one is ongoing
  bool _isConnecting = false;
  // Timer for the 30-second timeout to redirect if no devices are found.
  Timer? _scanTimeoutTimer;

  @override
  void initState() {
    super.initState();
    // Start scanning when the dialog is initialized.
    widget.bluetoothManager.startScan();
    _startScanTimeoutTimer(); // Start the timeout timer.
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel(); // Cancel the timer to prevent memory leaks.
    super.dispose();
  }

  /// Starts a 30-second timer to check if any Bluetooth devices have been found.
  /// If the timer expires and no devices are found, it redirects to the SOSScreen.
  void _startScanTimeoutTimer() {
    _scanTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        // Check if no devices were found AND scanning is not currently active.
        // The `!widget.bluetoothManager.isScanning.value` is crucial to ensure
        // we don't redirect while the initial scan is still in progress.
        if (widget.bluetoothManager.scanResults.value.isEmpty &&
            !widget.bluetoothManager.isScanning.value) {
          // Check if the dialog is still open before popping.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Pop the current scan dialog.
          }
          // Only navigate if we are not already on SOSScreen or a similar emergency screen.
          // This check prevents pushing multiple SOS screens if the timer fires again.
          // A more robust check might involve route names or a global state.
          if (!ModalRoute.of(context)!.isFirst) {
            // Simple check if not root route
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      const HomeScreen()), // Navigate to HomeScreen.
            );
          }
        }
      }
    });
  }

  /// Initiates connection to the selected Bluetooth device.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return; // Prevent multiple connection attempts

    // If a connection attempt is made, cancel the timeout timer
    // because the user has interacted, indicating they are not waiting for a scan timeout.
    _scanTimeoutTimer?.cancel();

    setState(() {
      _isConnecting = true; // Set connecting flag
    });

    final connectedDevice =
        await widget.bluetoothManager.connectToDevice(device);

    if (mounted) {
      setState(() {
        _isConnecting = false; // Reset connecting flag
      });
      if (connectedDevice != null) {
        // If connection is successful, pop the dialog with the connected device.
        Navigator.of(context).pop(connectedDevice);
      } else {
        // If connection failed, and no devices were found in total yet,
        // restart the timer to potentially trigger the SOS screen later.
        if (widget.bluetoothManager.scanResults.value.isEmpty) {
          _startScanTimeoutTimer(); // Restart timer only if no devices were found at all
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to all three ValueNotifiers from BluetoothManager to update the UI.
    return ValueListenableBuilder<List<ScanResult>>(
      valueListenable: widget.bluetoothManager.scanResults,
      builder: (context, results, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.bluetoothManager.isScanning,
          builder: (context, isScanning, __) {
            return ValueListenableBuilder<String>(
              valueListenable: widget.bluetoothManager.statusText,
              builder: (context, statusText, ___) {
                return AlertDialog(
                  title: const Text("Select a Device"), // Added const
                  content: SizedBox(
                    width: double.maxFinite,
                    // Display loading indicator or scan results based on state.
                    child: (isScanning && results.isEmpty) ||
                            statusText.contains("Connecting") ||
                            _isConnecting
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(), // Added const
                                const SizedBox(height: 16), // Added const
                                Text(
                                    statusText), // Display status from BluetoothManager
                              ],
                            ),
                          )
                        : results.isEmpty
                            ? Center(
                                child: Text(
                                    statusText)) // Display "No devices found" or other messages
                            : ListView.builder(
                                shrinkWrap: true, // Only occupy needed space
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final result = results[index];
                                  return ListTile(
                                    title: Text(
                                      result.device.platformName.isNotEmpty
                                          ? result.device.platformName
                                          : 'Unknown Device',
                                    ),
                                    subtitle: Text(
                                      result.device.remoteId.toString(),
                                    ),
                                    // Disable tap if already connecting to avoid race conditions.
                                    onTap: _isConnecting
                                        ? null
                                        : () => _connectToDevice(result.device),
                                  );
                                },
                              ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Close'), // Added const
                      onPressed: _isConnecting
                          ? null
                          : () => Navigator.of(context)
                              .pop(null), // Disable close during connection
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
