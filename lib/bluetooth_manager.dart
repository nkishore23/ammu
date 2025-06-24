import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages all Bluetooth scanning and connection logic, providing state
/// updates via ValueNotifiers.
class BluetoothManager {
  /// Notifier for discovered scan results.
  final ValueNotifier<List<ScanResult>> scanResults =
      ValueNotifier<List<ScanResult>>([]);

  /// Notifier for the current scanning state (true if scanning, false otherwise).
  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);

  /// Notifier for informational or error messages to display on the UI.
  final ValueNotifier<String> statusText = ValueNotifier<String>("");

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  /// Constructor: Initializes the BluetoothManager and sets up a listener
  /// for Bluetooth adapter state changes.
  BluetoothManager() {
    // Listen to adapter state changes to provide real-time feedback.
    // For example, if Bluetooth is turned off, update statusText.
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state != BluetoothAdapterState.on && !isScanning.value) {
        statusText.value =
            "Bluetooth is ${state.toString().split('.').last.toLowerCase()}. Please turn it on.";
      } else if (state == BluetoothAdapterState.on && !isScanning.value) {
        statusText.value = "Bluetooth is On. Ready to scan.";
      }
    });
  }

  /// Checks and requests necessary Bluetooth and location permissions.
  /// Returns true if all required permissions are granted, false otherwise.
  Future<bool> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // Check if all requested permissions are granted.
    return statuses.values.every((status) => status.isGranted);
  }

  /// Initiates a Bluetooth device scan.
  /// Handles permissions, Bluetooth adapter state, and scan results.
  Future<void> startScan() async {
    if (isScanning.value) {
      // A scan is already in progress, prevent duplicate scans.
      statusText.value = "Scan already in progress.";
      return;
    }

    try {
      // 1. Check for necessary permissions.
      if (!await _checkPermissions()) {
        statusText.value = "Bluetooth permissions are required to scan.";
        return;
      }

      // 2. Ensure Bluetooth adapter is turned on.
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        statusText.value = "Please turn on Bluetooth to scan for devices.";
        return;
      }

      // Prepare for scanning: clear previous results and update status.
      isScanning.value = true;
      statusText.value = "Scanning for devices...";
      scanResults.value = []; // Clear previous scan results

      // Start listening to scan results stream.
      // This listener will populate `scanResults.value` as devices are found.
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults.value = results;
      });

      // Start the actual Bluetooth scan with a timeout.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // After the scan completes (either by timeout or manual stop), update state.
      isScanning.value = false;
      if (scanResults.value.isEmpty) {
        statusText.value = "No Bluetooth devices found.";
      } else {
        statusText.value =
            "Scan complete. Found ${scanResults.value.length} devices.";
      }
    } catch (e) {
      // Catch and report any errors during the scanning process.
      statusText.value = "Error during scan: ${e.toString()}";
      isScanning.value = false; // Ensure scanning state is reset on error
    }
  }

  /// Connects to a given Bluetooth device.
  ///
  /// NOTE: This implementation currently *mocks* a successful connection
  /// for demonstration purposes. In a real application, you would uncomment
  /// the actual connection logic and handle success/failure appropriately.
  Future<BluetoothDevice?> connectToDevice(BluetoothDevice device) async {
    // If a scan is active, stop it before attempting connection.
    if (isScanning.value) {
      await FlutterBluePlus.stopScan();
      isScanning.value = false; // Update UI state
    }

    statusText.value =
        "Attempting to connect to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}...";

    // --- MOCKED CONNECTION LOGIC (for demonstration purposes) ---
    // In a real scenario, you would implement the actual device connection here.
    await Future.delayed(
        const Duration(seconds: 2)); // Simulate connection delay
    statusText.value = "Connection successful!";
    return device; // Return the device as if connected

    /* // --- REAL CONNECTION LOGIC (uncomment and use in production) ---
    try {
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      statusText.value = "Connection successful with ${device.platformName}!";
      // You might want to discover services here:
      // List<BluetoothService> services = await device.discoverServices();
      // services.forEach((service) {
      //   // Do something with services and characteristics
      // });
      return device;
    } catch (e) {
      statusText.value = "Connection Failed with ${device.platformName}. Please try again: ${e.toString()}";
      await device.disconnect(); // Ensure disconnection on failure
      return null;
    }
    */
  }

  /// Disposes of all active subscriptions and stops any ongoing scan.
  void dispose() {
    FlutterBluePlus
        .stopScan(); // Ensure scan is stopped when manager is disposed
    _scanResultsSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    scanResults.dispose();
    isScanning.dispose();
    statusText.dispose();
  }
}
