import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // For handling permissions

class BluetoothManager {
  // ValueNotifiers to update UI based on Bluetooth state
  final ValueNotifier<List<ScanResult>> scanResults = ValueNotifier([]);
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<String> statusText =
      ValueNotifier('Initializing Bluetooth...');
  final ValueNotifier<BluetoothAdapterState> bluetoothState =
      ValueNotifier(BluetoothAdapterState.unknown);
  // NEW: ValueNotifier to signal when a scan completes with no devices found
  final ValueNotifier<bool> scanCompletedNoDevicesFound = ValueNotifier(false);

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  BluetoothManager() {
    _initialize();
  }

  /// Initializes Bluetooth manager, subscribes to adapter state changes.
  Future<void> _initialize() async {
    _bluetoothStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      bluetoothState.value = state;
      _updateStatusText(state);
      // If Bluetooth turns on while dialog is open, we might want to automatically start scan
      if (state == BluetoothAdapterState.on && !isScanning.value) {
        startScan(); // Attempt to start scan if Bluetooth turns on
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      isScanning.value = scanning;
      if (!scanning) {
        // Scan has stopped
        if (scanResults.value.isEmpty) {
          statusText.value = 'No devices found.';
          scanCompletedNoDevicesFound.value = true; // Signal no devices found
        } else {
          statusText.value = 'Scan finished. Select a device.';
          scanCompletedNoDevicesFound.value =
              false; // Reset if devices were found
        }
      } else {
        // Scanning started
        statusText.value = 'Scanning for devices...';
        scanCompletedNoDevicesFound.value = false; // Reset when scan starts
        scanResults.value = []; // Clear results for new scan
      }
    });

    // Check initial state
    bluetoothState.value = await FlutterBluePlus.adapterState.first;
    _updateStatusText(bluetoothState.value);
  }

  /// Updates the status text based on the Bluetooth adapter state.
  void _updateStatusText(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.unavailable:
        statusText.value = 'Bluetooth is not available on this device.';
        break;
      case BluetoothAdapterState.unauthorized:
        statusText.value = 'Bluetooth permissions not granted.';
        break;
      case BluetoothAdapterState.off:
        statusText.value = 'Bluetooth is OFF. Please turn it ON.';
        break;
      case BluetoothAdapterState.on:
        statusText.value = 'Bluetooth is ON. Ready to scan.';
        break;
      case BluetoothAdapterState.turningOn:
        statusText.value = 'Bluetooth is turning ON...';
        break;
      case BluetoothAdapterState.turningOff:
        statusText.value = 'Bluetooth is turning OFF...';
        break;
      default:
        statusText.value = 'Unknown Bluetooth state.';
        break;
    }
  }

  /// Requests necessary Bluetooth permissions (Bluetooth Scan, Connect, Advertise).
  /// For Android 12+ (SDK 31+), these are runtime permissions.
  Future<bool> requestPermissions() async {
    // Request Bluetooth permissions for Android 12+ (SDK 31+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus =
          await Permission.bluetoothConnect.request();
      final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise
          .request(); // May not be strictly needed for client apps
      final locationStatus = await Permission.locationWhenInUse
          .request(); // Location is often required for Bluetooth scanning

      if (bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          bluetoothAdvertiseStatus
              .isGranted && // Consider if this is needed for your app
          locationStatus.isGranted) {
        return true;
      } else {
        statusText.value =
            'Bluetooth permissions denied. Please enable them in settings.';
        return false;
      }
    }
    // For iOS, usually Bluetooth usage is requested implicitly or via Info.plist.
    // Location permission might still be needed for scanning.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final locationStatus = await Permission.locationWhenInUse.request();
      if (!locationStatus.isGranted) {
        statusText.value = 'Location permission denied for Bluetooth scanning.';
        return false;
      }
    }
    return true; // Assume true for other platforms or if permissions already granted
  }

  /// Starts scanning for Bluetooth devices.
  Future<void> startScan() async {
    scanResults.value = []; // Clear previous results
    scanCompletedNoDevicesFound.value = false; // Reset signal
    statusText.value = 'Checking permissions...';

    if (bluetoothState.value != BluetoothAdapterState.on) {
      statusText.value = 'Bluetooth is OFF. Please turn it ON first.';
      return;
    }

    // Request permissions before scanning
    if (!(await requestPermissions())) {
      return; // If permissions are not granted, stop here
    }

    if (isScanning.value) {
      FlutterBluePlus
          .stopScan(); // Stop any ongoing scan before starting a new one
      await Future.delayed(
          const Duration(milliseconds: 500)); // Give it a moment to stop
    }

    try {
      statusText.value = 'Scanning for devices...';
      FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 15)); // Scan for 15 seconds
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults.value = results;
        if (results.isNotEmpty) {
          statusText.value =
              'Found ${results.length} device(s). Tap to connect.';
        }
      });
    } catch (e) {
      statusText.value = 'Error starting scan: ${e.toString()}';
      isScanning.value = false;
      print('Error starting scan: $e');
    }
  }

  /// Stops the current Bluetooth scan.
  Future<void> stopScan() async {
    try {
      FlutterBluePlus.stopScan();
      isScanning.value = false;
      _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  /// Connects to a given Bluetooth device.
  /// Returns the connected device on success, null on failure.
  Future<BluetoothDevice?> connectToDevice(BluetoothDevice device) async {
    statusText.value =
        'Connecting to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}...';
    try {
      // Stop scan before connecting to save power and prevent interference
      await stopScan();

      await device.connect(
          autoConnect: false); // AutoConnect false for explicit connection
      statusText.value = 'Connected to ${device.platformName}.';
      return device;
    } catch (e) {
      statusText.value =
          'Failed to connect to ${device.platformName}: ${e.toString()}';
      print('Connection failed: $e');
      return null;
    }
  }

  /// Disposes all resources and listeners. Call this when the BluetoothManager is no longer needed.
  void dispose() {
    _scanResultsSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    _isScanningSubscription?.cancel();
    FlutterBluePlus.stopScan(); // Ensure scan is stopped
    scanResults.dispose();
    isScanning.dispose();
    statusText.dispose();
    bluetoothState.dispose();
    scanCompletedNoDevicesFound.dispose(); // Dispose the new notifier
  }
}
