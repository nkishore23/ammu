import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'success_screen.dart';
import 'home_screen.dart'; // Import your home screen
import 'dart:async'; // Import for Timer

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final List<ScanResult> _scanResults = [];
  final Set<String> _foundDeviceIds = {};
  bool _isScanning = false;
  Timer? _timeoutTimer;
  static const int _scanTimeoutSeconds =
      30; // Timeout for the entire scan process

  @override
  void initState() {
    super.initState();
    _startScanWithTimeout(); // Start scan with the timeout logic
  }

  void _startScanWithTimeout() async {
    // Clear previous scan results and IDs
    _scanResults.clear();
    _foundDeviceIds.clear();

    // Start the timeout timer
    _timeoutTimer = Timer(const Duration(seconds: _scanTimeoutSeconds), () {
      if (mounted) {
        stopScan(); // Ensure scan is stopped
        if (_scanResults.isEmpty) {
          // If no devices were found after the timeout, navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SOSScreen()),
          );
        }
      }
    });

    setState(() => _isScanning = true);

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final id = result.device.remoteId.id;
        if (!_foundDeviceIds.contains(id)) {
          setState(() {
            _foundDeviceIds.add(id);
            _scanResults.add(result);
          });
        }
      }
    });

    // Start the FlutterBluePlus scan
    await FlutterBluePlus.startScan(
      timeout: const Duration(
          seconds: _scanTimeoutSeconds), // FlutterBluePlus timeout, max 30s
      androidUsesFineLocation: true,
    );

    // This `then` block will execute when `FlutterBluePlus.startScan` completes
    // (either by finding something and stopping, or by reaching its own timeout).
    // We still rely on our custom `_timeoutTimer` for the 30-second logic
    // related to no devices found.
    FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && _isScanning) {
        // If FlutterBluePlus stops scanning and we were still expecting it
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      setState(() => _isScanning = false);
    }
    _timeoutTimer?.cancel(); // Cancel the custom timeout timer
  }

  void connectToDevice(BluetoothDevice device) async {
    stopScan(); // Stop scanning and cancel the timer immediately
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      _startScanWithTimeout(); // Optionally restart scan after connection failure
    }
  }

  @override
  void dispose() {
    stopScan(); // Ensure all scanning and timers are stopped
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Devices"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            stopScan(); // Stop scan and cancel timer when navigating back
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _isScanning
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              : ElevatedButton(
                  onPressed: _startScanWithTimeout, // Use the new method
                  child: const Text("Rescan Devices"),
                ),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isScanning)
                          const Text("Scanning for devices...")
                        else
                          const Text("No devices found yet. Try rescanning."),
                        if (!_isScanning &&
                            _scanResults
                                .isEmpty) // Show message after scan stops and no devices are found
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "If no devices appear after 30 seconds, you will be redirected to the home screen.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;

                      return ListTile(
                        title: Text(
                          device.platformName.isNotEmpty
                              ? device.platformName
                              : "Unknown Device",
                        ),
                        subtitle: Text("ID: ${device.remoteId.id}"),
                        trailing: ElevatedButton(
                          child: const Text("Connect"),
                          onPressed: () => connectToDevice(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
