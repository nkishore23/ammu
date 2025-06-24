import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ammu_app/services/bluetooth_manager.dart'; // Import the manager

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

  // Listeners for BluetoothManager state changes
  late VoidCallback _scanCompletedNoDevicesListener;
  late VoidCallback _bluetoothStateListener; // For Bluetooth state changes

  @override
  void initState() {
    super.initState();

    // Initialize listeners
    _scanCompletedNoDevicesListener = () {
      if (widget.bluetoothManager.scanCompletedNoDevicesFound.value &&
          mounted) {
        // If no devices were found and scan completed, pop the dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context)
              .pop(null); // Pop with null, signalling no device connected
        }
      }
    };

    _bluetoothStateListener = () {
      // If Bluetooth state changes to ON while dialog is open, restart scan logic
      if (widget.bluetoothManager.bluetoothState.value ==
              BluetoothAdapterState.on &&
          !widget.bluetoothManager.isScanning.value) {
        _startScanBasedOnBluetoothState();
      }
    };

    // Add listeners
    widget.bluetoothManager.scanCompletedNoDevicesFound
        .addListener(_scanCompletedNoDevicesListener);
    widget.bluetoothManager.bluetoothState.addListener(_bluetoothStateListener);

    // Initial check and scan start
    _startScanBasedOnBluetoothState();
  }

  @override
  void dispose() {
    // Remove listeners
    widget.bluetoothManager.scanCompletedNoDevicesFound
        .removeListener(_scanCompletedNoDevicesListener);
    widget.bluetoothManager.bluetoothState
        .removeListener(_bluetoothStateListener);
    super.dispose();
  }

  /// Checks Bluetooth state and starts scanning or prompts user.
  Future<void> _startScanBasedOnBluetoothState() async {
    final state = widget.bluetoothManager.bluetoothState.value;
    if (state == BluetoothAdapterState.on) {
      await widget.bluetoothManager.startScan();
    } else {
      widget.bluetoothManager.statusText.value =
          'Bluetooth is ${state.name.toUpperCase()}. Please turn it ON.';
    }
  }

  /// Initiates connection to the selected Bluetooth device.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return; // Prevent multiple connection attempts

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
        // Connection failed, update status text for the user
        widget.bluetoothManager.statusText.value =
            'Connection failed. Try again or select another device.';
      }
    }
  }

  /// Helper to toggle Bluetooth state (ON/OFF).
  Future<void> _toggleBluetooth() async {
    if (widget.bluetoothManager.bluetoothState.value ==
        BluetoothAdapterState.off) {
      await FlutterBluePlus.turnOn();
      // BluetoothManager's listener will update statusText and potentially start scan
    } else if (widget.bluetoothManager.bluetoothState.value ==
        BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOff();
      // BluetoothManager's listener will update statusText
    }
  }

  /// Helper to request permissions again if denied.
  Future<void> _requestPermissionsAndScan() async {
    final granted = await widget.bluetoothManager.requestPermissions();
    if (granted) {
      await _startScanBasedOnBluetoothState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to all ValueNotifiers from BluetoothManager to update the UI.
    return ValueListenableBuilder<List<ScanResult>>(
      valueListenable: widget.bluetoothManager.scanResults,
      builder: (context, results, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.bluetoothManager.isScanning,
          builder: (context, isScanning, __) {
            return ValueListenableBuilder<String>(
              valueListenable: widget.bluetoothManager.statusText,
              builder: (context, statusText, ___) {
                return ValueListenableBuilder<BluetoothAdapterState>(
                  valueListenable: widget.bluetoothManager.bluetoothState,
                  builder: (context, bluetoothState, ____) {
                    // `bluetoothState` here IS the enum value
                    bool showLoading = (isScanning &&
                            results.isEmpty &&
                            bluetoothState == BluetoothAdapterState.on) ||
                        _isConnecting;
                    bool showDeviceList = !showLoading && results.isNotEmpty;
                    bool showStatusMessage = !showLoading && !showDeviceList;

                    return AlertDialog(
                      title: const Text("Select a Device",
                          textAlign: TextAlign.center),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 300, // Fixed height for content area
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showLoading)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      statusText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              )
                            else if (showDeviceList)
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final result = results[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      elevation: 1,
                                      child: ListTile(
                                        title: Text(
                                          result.device.platformName.isNotEmpty
                                              ? result.device.platformName
                                              : 'Unknown Device',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                            'ID: ${result.device.remoteId.str}\nRSSI: ${result.rssi} dBm'),
                                        onTap: _isConnecting
                                            ? null // Disable tap during connection
                                            : () =>
                                                _connectToDevice(result.device),
                                        trailing: _isConnecting &&
                                                widget.bluetoothManager
                                                    .statusText.value
                                                    .contains(result
                                                        .device.platformName)
                                            ? const CircularProgressIndicator(
                                                strokeWidth: 2)
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              )
                            else if (showStatusMessage)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Text(
                                      statusText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: bluetoothState ==
                                                    BluetoothAdapterState.off ||
                                                bluetoothState ==
                                                    BluetoothAdapterState
                                                        .unauthorized
                                            ? Colors
                                                .red // Highlight critical issues
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    if (bluetoothState ==
                                        BluetoothAdapterState.off)
                                      ElevatedButton(
                                        onPressed: _toggleBluetooth,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0d47a1),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Turn On Bluetooth'),
                                      )
                                    else if (bluetoothState ==
                                        BluetoothAdapterState.unauthorized)
                                      ElevatedButton(
                                        onPressed: _requestPermissionsAndScan,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0d47a1),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Grant Permissions'),
                                      )
                                    else if (!isScanning && results.isEmpty)
                                      // If not scanning and no results, and not off/unauthorized, allow rescan
                                      ElevatedButton(
                                        onPressed:
                                            widget.bluetoothManager.startScan,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0d47a1),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Rescan Devices'),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: _isConnecting
                              ? null // Disable cancel during connection
                              : () {
                                  widget.bluetoothManager
                                      .stopScan(); // Stop scan if user cancels
                                  Navigator.of(context)
                                      .pop(null); // Pop dialog with null result
                                },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
