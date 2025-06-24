import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// This is a simple placeholder service to simulate saving a device.
// In a real application, you would use persistent storage like shared_preferences,
// hive, or a database (e.g., SQLite, Firestore) to store device information
// so it persists across app launches.

class DeviceService {
  // Private static instance of the service
  static final DeviceService _instance = DeviceService._internal();

  // Public static getter to access the singleton instance
  static DeviceService get instance => _instance;

  // Private constructor to prevent external instantiation
  DeviceService._internal();

  // Simple in-memory storage for the connected device
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  void saveDevice(BluetoothDevice device) {
    _connectedDevice = device;
    print('Device saved: ${device.platformName} (${device.remoteId})');
    // In a real app:
    // await SharedPreferences.getInstance().setString('last_connected_device_id', device.remoteId.str);
    // await SharedPreferences.getInstance().setString('last_connected_device_name', device.platformName);
  }

  // In a real app, you'd have a method to load the device:
  // Future<BluetoothDevice?> loadLastConnectedDevice() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final deviceId = prefs.getString('last_connected_device_id');
  //   if (deviceId != null) {
  //     // You would need to re-scan for this device or use a FlutterBluePlus
  //     // method to get a BluetoothDevice object from an ID.
  //     // This is often complex as the device might not be discoverable or in range.
  //     print('Attempting to load last connected device: $deviceId');
  //     return null; // For this simple example, just return null.
  //   }
  //   return null;
  // }
}
