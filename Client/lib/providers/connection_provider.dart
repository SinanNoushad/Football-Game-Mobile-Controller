import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:multicast_dns/multicast_dns.dart';
import '../controller_settings.dart';
//import 'package:provider/provider.dart';

class ConnectionProvider extends ChangeNotifier {
  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  String? serverIp;

  bool get isConnected => _isConnected;

  /// Connects to the server and sends the "connect" command when open.
  void connect(String ipAddress, String port) async {
    try {
      // Establish the WebSocket connection.
      _channel = IOWebSocketChannel.connect('ws://$ipAddress:$port');

      // Listen to the stream for incoming messages, errors, and closure.
      _channel!.stream.listen((message) {
        // You can handle incoming messages here if needed.
      }, onDone: () {
        _isConnected = false;
        notifyListeners();
      }, onError: (error) {
        _isConnected = false;
        notifyListeners();
      });

      // Set connection state.
      _isConnected = true;
      serverIp = ipAddress;
      notifyListeners();

      // Immediately after connecting, send the "connect" command.
      String controllerName =
          (await ControllerSettings.getControllerName()) ?? "Unknown";
      // Use a default value if the retrieved name is empty.
      if (controllerName.trim().isEmpty) {
        controllerName = "Unknown";
      }
      String controllerId = await ControllerSettings.getControllerId();

      // Build the connect command.
      final connectCommand = {
        'action': 'connect',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'controllerName': controllerName,
        'controllerId': controllerId,
      };

      String jsonCommand = jsonEncode(connectCommand);

      // Send the connect command over the WebSocket.
      _channel!.sink.add(jsonCommand);
      print("Sent connect command: $jsonCommand");
    } catch (e) {
      print("Connection error: $e");
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Uses mDNS to find servers and returns a list of server addresses.
  Future<List<String>> autoDetectServers({Duration timeout = const Duration(seconds: 5)}) async {
    List<String> servers = await discoverServers(timeout: timeout);
    return servers;
  }

  /// Uses mDNS to discover servers.
  Future<List<String>> discoverServers({Duration timeout = const Duration(seconds: 5)}) async {
    final String serviceType = '_pcserver._tcp';
    final MDnsClient client = MDnsClient();
    final List<String> servers = [];
    try {
      await client.start();
      final endTime = DateTime.now().add(timeout);

      // Lookup Ptr records for the service.
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(serviceType))) {
        if (DateTime.now().isAfter(endTime)) break;

        // Lookup the SRV records from the pointer.
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          if (DateTime.now().isAfter(endTime)) break;

          // Lookup the IP addresses for the service target.
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            if (DateTime.now().isAfter(endTime)) break;

            String ipAddress = ip.address.address;
            int port = srv.port;
            String server = '$ipAddress:$port';

            // Avoid duplicates.
            if (!servers.contains(server)) {
              servers.add(server);
              print('Discovered server at $server');
            }
          }
        }
      }
    } catch (e) {
      print('Error during mDNS discovery: $e');
    } finally {
      client.stop();
    }
    return servers;
  }

  /// Sends an action command (other than the connect command).
  bool sendAction(String action) {
    if (_isConnected && _channel != null) {
      final command = {
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _channel!.sink.add(jsonEncode(command));
      return true;
    } else {
      print('Not connected to server.');
      return false;
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
