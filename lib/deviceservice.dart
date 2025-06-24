import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  // Private constructor
  DeviceService._privateConstructor();

  // Singleton instance
  static final DeviceService _instance = DeviceService._privateConstructor();

  // Getter for singleton
  static DeviceService get instance => _instance;

  // In-memory reference
  BluetoothDevice? connectedDevice;

  // Save device (in memory + SharedPreferences)
  Future<void> saveDevice(BluetoothDevice device) async {
    connectedDevice = device;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', device.remoteId.toString());
    print('Device Saved: ${device.platformName} (${device.remoteId})');
  }

  // Load saved device from SharedPreferences
  Future<String?> getSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
  }

  // Get in-memory device
  BluetoothDevice? getDevice() => connectedDevice;

  // Clear everything
  Future<void> clearDevice() async {
    connectedDevice = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_id');
    print('Saved device cleared.');
  }
}
