import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
class BluetoothConnectionProvider extends ChangeNotifier {
  // List to hold discovered devices.
  final List<BluetoothDevice> _scannedDevices = [];
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;

  bool get isConnected =>
      _connectedDevice != null &&
      _connection != null &&
      _connection!.isConnected;
  List<BluetoothDevice> get scannedDevices => _scannedDevices;

  /// Start scanning (discovering) for Bluetooth devices.
  void startScan() {
    _scannedDevices.clear();

    // Begin device discovery.
    FlutterBluetoothSerial.instance.startDiscovery().listen(
      (BluetoothDiscoveryResult result) {
        final device = result.device;
        // Avoid duplicates by checking device addresses.
        if (!_scannedDevices.any((d) => d.address == device.address)) {
          _scannedDevices.add(device);
          notifyListeners();
        }
      },
      onError: (error) {
        print('Scan error: $error');
      },
    );
  }

  /// Connect to the selected Bluetooth device.
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Attempt to establish a connection using the device's address.
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _connectedDevice = device;
      notifyListeners();

      // Optionally listen to incoming data and handle disconnections.
      _connection!.input!.listen((data) {
        // Handle incoming data if needed.
        print('Data incoming: ${utf8.decode(data)}');
      }).onDone(() {
        print('Disconnected by remote request');
        _connectedDevice = null;
        _connection = null;
        notifyListeners();
      });
    } catch (e) {
      // Handle connection errors (for example, if already connected).
      print('Connection error: $e');
    }
  }

  /// Send an action command over the Bluetooth connection.
  Future<bool> sendAction(String action) async {
    if (_connection != null && _connection!.isConnected) {
      final command = {
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final data = utf8.encode(jsonEncode(command));
      try {
        // Write data to the Bluetooth connection.
        _connection!.output.add(data);
        // Wait until all data has been sent.
        await _connection!.output.allSent;
        return true;
      } catch (e) {
        print('Error writing data: $e');
        return false;
      }
    } else {
      print('Not connected to any Bluetooth device.');
      return false;
    }
  }


// Function to request Bluetooth permissions.
Future<bool> requestBluetoothPermissions() async {
  // Request the permissions required for Bluetooth on Android 12+.
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    // Uncomment if needed:
    // Permission.bluetoothAdvertise,
  ].request();

  // For devices below Android 12, you might need location permission:
  if (await Permission.location.request().isGranted) {
    statuses[Permission.location] = PermissionStatus.granted;
  }

  // Check if all required permissions are granted.
  bool allGranted = statuses.values.every((status) => status.isGranted);
  return allGranted;
}
}