import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ammu_app/services/bluetooth_manager.dart'; // Import the new manager
import 'package:ammu_app/services/device_service.dart'; // Assume this file exists for device saving
import 'package:ammu_app/widgets/scan_and_connect_dialog.dart'; // Import the new dialog
import 'package:ammu_app/home_screen.dart'; // Import MyApp which contains HomeScreen

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

  // Track if Bluetooth is enabled to control the animation and button state
  late ValueNotifier<BluetoothAdapterState> _bluetoothStateNotifier;

  @override
  void initState() {
    super.initState();
    _bluetoothManager = BluetoothManager();
    _bluetoothStateNotifier = _bluetoothManager.bluetoothState;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // A 2-second cycle for each ripple
    );

    _bluetoothStateNotifier.addListener(_updateAnimationAndButtonState);
    _updateAnimationAndButtonState(); // Set initial state
  }

  // Determines whether the animation should be repeating or stopped.
  void _updateAnimationAndButtonState() {
    if (_bluetoothStateNotifier.value == BluetoothAdapterState.on &&
        !_isActionInProgress) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
    if (mounted) {
      setState(() {}); // Rebuild to update button enabled state and text
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bluetoothManager.dispose();
    _bluetoothStateNotifier.removeListener(_updateAnimationAndButtonState);
    super.dispose();
  }

  /// Handles the entire pairing process, from showing the scan dialog
  /// to navigating to the home screen upon successful connection.
  Future<void> _handlePairingProcess() async {
    if (_isActionInProgress) return;

    final BluetoothAdapterState currentState =
        _bluetoothManager.bluetoothState.value;

    // --- Step 1: Check Bluetooth Adapter State ---
    if (currentState == BluetoothAdapterState.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bluetooth is not available on this device.')),
      );
      return;
    } else if (currentState == BluetoothAdapterState.off) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bluetooth is OFF. Please turn it ON to pair.')),
      );
      // Optionally, prompt to turn on Bluetooth or open settings
      // await FlutterBluePlus.turnOn(); // This might open system settings
      return;
    } else if (currentState == BluetoothAdapterState.unauthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Bluetooth permissions not granted. Please enable them in settings.')),
      );
      // --- Step 2: Request Permissions if unauthorized ---
      bool granted = await _bluetoothManager.requestPermissions();
      if (!granted) {
        return; // If permissions are still not granted, stop here
      }
      // If permissions were just granted, BluetoothManager's listener might
      // change state to 'on', and the button state will update via listener.
      // We can then re-call this method, or just wait for the user to tap again.
      if (_bluetoothManager.bluetoothState.value != BluetoothAdapterState.on) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Bluetooth state still not ready after permissions. Try again.')),
        );
        return;
      }
    } else if (currentState != BluetoothAdapterState.on) {
      // Handles states like turningOn/turningOff, or unknown
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Bluetooth is ${currentState.name}. Please wait or resolve the issue.')),
      );
      return;
    }

    // --- All prerequisites met, proceed to show scan dialog ---
    setState(() {
      _isActionInProgress = true;
      _animationController.stop(); // Stop animation while dialog is open
    });

    final BluetoothDevice? connectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ScanAndConnectDialog(bluetoothManager: _bluetoothManager),
    );

    // --- Handle result after dialog closes ---
    if (mounted) {
      setState(() {
        _isActionInProgress = false; // Reset action flag
        _updateAnimationAndButtonState(); // Restart animation if applicable
      });

      if (connectedDevice != null) {
        DeviceService.instance.saveDevice(connectedDevice);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully paired with ${connectedDevice.platformName}')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Dialog was cancelled OR no devices were found. Navigate to HomeScreen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Pairing cancelled or no device found. Navigating to Home.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  /// Builds a single ripple circle for the "Pair" button animation.
  Widget _buildRipple(double animationOffset) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double normalizedTime =
            (_animationController.value + animationOffset) % 1.0;
        final double easedProgress =
            Curves.easeInOutQuad.transform(normalizedTime);
        const double baseButtonRadius = 65.0;
        const double maxRippleRadius = 180.0;
        final double currentRadius = baseButtonRadius +
            (maxRippleRadius - baseButtonRadius) * easedProgress;
        const double startOpacity = 0.6;
        const double endOpacity = 0.0;
        final double opacity =
            startOpacity + (endOpacity - startOpacity) * easedProgress;
        final double clampedOpacity = opacity.clamp(0.0, 1.0);

        return CircleAvatar(
          radius: currentRadius,
          backgroundColor: const Color(0xFF0d47a1).withOpacity(clampedOpacity),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BluetoothAdapterState>(
      valueListenable: _bluetoothStateNotifier,
      builder: (context, bluetoothAdapterState, child) {
        final bool isBluetoothOnAndReady =
            bluetoothAdapterState == BluetoothAdapterState.on;
        final bool isButtonEnabled =
            isBluetoothOnAndReady && !_isActionInProgress;
        String buttonText;
        if (_isActionInProgress) {
          buttonText = 'Pairing...';
        } else if (!isBluetoothOnAndReady) {
          buttonText = 'Bluetooth Off';
        } else {
          buttonText = 'Pair';
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF003366),
            title: const Text(
              'SMS Add on Services',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const Text(
                  'Tap on pair Button to pair\nGPS Smart Watch / Chip',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(flex: 1),
                GestureDetector(
                  onTap: isButtonEnabled ? _handlePairingProcess : null,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isBluetoothOnAndReady &&
                                !_isActionInProgress) ...[
                              _buildRipple(0.0),
                              _buildRipple(0.25),
                              _buildRipple(0.50),
                              _buildRipple(0.75),
                            ],
                            child!,
                          ],
                        );
                      },
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFF0d47a1),
                        child: _isActionInProgress
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: buttonText.length > 10
                                      ? 20
                                      : 32, // Adjust font size for longer text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        );
      },
    );
  }
}
