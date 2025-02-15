import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/controller_screen.dart';
import 'providers/connection_provider.dart';
import 'providers/bluetooth_connection_provider.dart';
import 'providers/button_position_provider.dart'; // Add this import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Define default positions (use fixed values)
    final defaultPositions = {
      'throughButton': const Offset(110, 110),
      'sprintButton': const Offset(10, 20),
      'passButton': const Offset(130, 20),
      'shootButton': const Offset(20, 130),
      'goalkeeperButton': const Offset(85, 200),
      'lbButton': const Offset(0, 0),
      'rbButton': const Offset(0, 0),
      'ltButton': const Offset(0, 70),
      'rtButton': const Offset(0, 70),
      'dpadButton': const Offset(250, 55),
      'rightJoystickButton': const Offset(210, 30),
      'leftJoystickButton': const Offset(20, 20),
      'selectStartGroup': const Offset(315, 100),
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ButtonPositionProvider(defaultPositions),
          ),
          ChangeNotifierProvider<ConnectionProvider>(
            create: (_) => ConnectionProvider(),
          ),
          ChangeNotifierProvider<BluetoothConnectionProvider>(
            create: (_) => BluetoothConnectionProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ControllerScreen(), // Removed const here
    );
  }
}