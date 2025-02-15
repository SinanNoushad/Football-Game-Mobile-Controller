import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Your custom widgets:
import '../widgets/lb_button.dart';
import '../widgets/rb_button.dart';
import '../widgets/lt_button.dart';
import '../widgets/rt_button.dart';
import '../widgets/pass_button.dart';
import '../widgets/shoot_button.dart';
import '../widgets/through_button.dart';
import '../widgets/sprint_button.dart';
import '../widgets/right_joystick.dart';
import '../widgets/dpad_button.dart';
import '../widgets/start_button.dart';
import '../widgets/select_button.dart';
import '../widgets/left_joystick.dart';
import '../widgets/goalkeeper_button.dart';

// Providers:
import '../providers/connection_provider.dart';
import '../providers/bluetooth_connection_provider.dart';
import 'ControllerSettingsScreen.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/button_position_provider.dart';

// Define an enum for connection modes.
enum ConnectionMode { wifi, bluetooth }

class ControllerScreen extends StatefulWidget {
  @override
  _ControllerScreenState createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  late ConnectionProvider connectionProvider;
  // (Bluetooth provider is available via Provider as well.)
  Timer? _throttleTimer;
  Timer? _progressTimer;
  double _progressValue = 0.0;
  late Stopwatch _stopwatch;
  bool isConnectionDialogOpen = false;
  int _backPressCount = 0;
  Timer? _backPressTimer;

  // Track the selected connection mode.
  ConnectionMode _selectedConnectionMode = ConnectionMode.wifi;

  @override
  void initState() {
    super.initState();
    connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
  }

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    _progressTimer?.cancel();
    _throttleTimer?.cancel();
    _backPressTimer?.cancel();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final buttonPositionProvider = Provider.of<ButtonPositionProvider>(context);
    final connectionProv = Provider.of<ConnectionProvider>(context);
    final btProvider = Provider.of<BluetoothConnectionProvider>(context);
    bool isConnected =
        connectionProv.isConnected || btProvider.isConnected;

    IconData connectionIcon = Icons.wifi_off;
    if (connectionProv.isConnected) {
      connectionIcon = Icons.wifi;
    } else if (btProvider.isConnected) {
      connectionIcon = Icons.bluetooth;
    }

    return PopScope(
      canPop: _backPressCount >= 2,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        _backPressCount++;
        
        _backPressTimer?.cancel();
        _backPressTimer = Timer(Duration(seconds: 1), () {
          _backPressCount = 0;
        });
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Connection button at the top.
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onLongPressStart: (_) => startConnectionTimer(),
                onLongPressEnd: (_) => cancelConnectionTimer(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green[300]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          connectionIcon,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (_progressValue > 0.0)
                      SizedBox(
                        width: 160,
                        height: 60,
                        // Uncomment below to display a progress indicator:
                        // child: CircularProgressIndicator(
                        //   value: _progressValue,
                        //   strokeWidth: 4.0,
                        //   valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        // ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // The controller UI with buttons and joysticks.
          buildControllerUI(),
        ],
      ),
    )
    );
  }

  void startConnectionTimer() {
    _stopwatch = Stopwatch()..start();
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _progressValue = _stopwatch.elapsed.inMilliseconds / 1000;
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          timer.cancel();
          _stopwatch.stop();
          if (!isConnectionDialogOpen) {
            isConnectionDialogOpen = true;
            showConnectionDialog();
          }
        }
      });
    });
  }

  void cancelConnectionTimer() {
    if (_progressTimer != null && _progressTimer!.isActive) {
      _progressTimer!.cancel();
    }
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
    setState(() {
      _progressValue = 0.0;
    });
  }

  void showConnectionDialog() {
    showDialog(
  context: context,
  barrierDismissible: true,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Consumer<ButtonPositionProvider>(
          builder: (context, positionProvider, _) {
            return AlertDialog(
              title: Text('Connect to Server'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildConnectionUI(setStateDialog),
                    SizedBox(height: 20),
                    // Add edit button row here
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ControllerSettingsScreen(),
                              ),
                            );
                          },
                          child: Text("Change Name"),
                        ),
                        IconButton(
                          icon: Icon(positionProvider.editMode
                              ? Icons.save
                              : Icons.edit),
                          onPressed: () {
                            positionProvider.toggleEditMode();
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Edit Button Layout',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    isConnectionDialogOpen = false;
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  },
  ).then((_) {isConnectionDialogOpen = false;});
    }


  /// This method builds the connection UI with a toggle between Wi‑Fi and Bluetooth.
    Widget buildConnectionUI(void Function(void Function()) setStateDialog) {
    final connectionProv = Provider.of<ConnectionProvider>(context, listen: false);
    final btProvider = Provider.of<BluetoothConnectionProvider>(context, listen: false);

     return Container(
    padding: EdgeInsets.all(10),
    color: Colors.white70,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          connectionProv.isConnected
              ? 'Connected via Wi‑Fi to ${connectionProv.serverIp}'
              : btProvider.isConnected
              ? 'Connected via Bluetooth'
              : 'Not connected',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ToggleButtons(
          children: [Text('Wi‑Fi'), Text('Bluetooth')],
          isSelected: [
            _selectedConnectionMode == ConnectionMode.wifi,
            _selectedConnectionMode == ConnectionMode.bluetooth,
          ],
          onPressed: (int index) {
            setStateDialog(() {
              _selectedConnectionMode =
              index == 0 ? ConnectionMode.wifi : ConnectionMode.bluetooth;
            });
          },
        ),
        SizedBox(height: 10),
          if (_selectedConnectionMode == ConnectionMode.wifi) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IP Address TextField.
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: ipController,
                    decoration: InputDecoration(
                      labelText: 'Server IP Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Port TextField.
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Connect button.
                ElevatedButton(
                  onPressed: () {
                    if (ipController.text.isNotEmpty &&
                        portController.text.isNotEmpty) {
                      connectionProv.connect(ipController.text, portController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter both IP and Port.')),
                      );
                    }
                  },
                  child: Text('Connect'),
                ),
                SizedBox(width: 10),
                // Auto‑Detect button.
                ElevatedButton(
                  onPressed: () {
                    connectionProv.autoDetectServers().then((servers) {
                      if (servers.isNotEmpty) {
                        if (servers.length == 1) {
                          // Only one server found—auto-fill the fields and connect.
                          String server = servers[0];
                          List<String> parts = server.split(':');
                          ipController.text = parts[0];
                          portController.text = parts[1];
                          connectionProv.connect(parts[0], parts[1]);
                        } else {
                          // Multiple servers found—present a selection dialog.
                          showServerSelectionDialog(servers);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No servers found. Please enter IP manually.'),
                          ),
                        );
                      }
                    });
                  },
                  child: Text('Auto‑Detect'),
                ),
              ],
            ),
          ] else ...[
            // Show Bluetooth UI if selected.
            // ElevatedButton(
            //   onPressed: () {
            //     btProvider.startScan();
            //   },
            //   child: Text('Scan for Bluetooth Devices'),
            // ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Check if Bluetooth is enabled
                  bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
                  if (!isEnabled) {
                    await FlutterBluetoothSerial.instance.requestEnable();
                    return;
                  }

                  bool granted = await Provider.of<BluetoothConnectionProvider>(
                    context, 
                    listen: false
                  ).requestBluetoothPermissions();
                  
                  if (granted) {
                    Provider.of<BluetoothConnectionProvider>(
                      context, 
                      listen: false
                    ).startScan();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bluetooth permissions not granted')),
                    );
                  }
                } catch (e) {
                  print('Error during Bluetooth scan: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error starting Bluetooth scan')),
                  );
                }
              },
              child: Text('Scan for Bluetooth Devices'),
            ),
          SizedBox(height: 10),
          Container(
            height: 150,
            child: Consumer<BluetoothConnectionProvider>(
                builder: (context, btProv, child) {
                  if (btProv.scannedDevices.isEmpty) {
                    return Center(child: Text('No devices found.'));
                  }
                  return ListView.builder(
                    itemCount: btProv.scannedDevices.length,
                    itemBuilder: (context, index) {
                      final device = btProv.scannedDevices[index];
                      final deviceName = (device.name != null && device.name!.isNotEmpty)
                          ? device.name
                          : "Unknown Device";
                      return ListTile(
                        title: Text(deviceName!),
                        subtitle: Text(device.address),
                        onTap: () async {
                          await btProv.connectToDevice(device);
                          Navigator.of(context).pop(); // Close the dialog.
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }




Widget buildControllerUI() {
  final buttonPositionProvider = Provider.of<ButtonPositionProvider>(context);
  final screenSize = MediaQuery.of(context).size;

  return Stack(
    children: [
      _buildPositionedButton(
        key: 'throughButton',
        defaultPosition: Offset(110, 110),
        anchorRight: true,
        anchorBottom: true,
        child: ThroughButton(width: 80, height: 80),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(80, 80),
      ),
      _buildPositionedButton(
        key: 'sprintButton',
        defaultPosition: Offset(10, 20),
        anchorRight: true,
        anchorBottom: true,
        child: SprintButton(width: 100, height: 100),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(100, 100),
      ),
            _buildPositionedButton(
        key: 'passButton',
        defaultPosition: Offset(130, 20),
        anchorRight: true,
        anchorBottom: true,
        child: PassButton(width: 80, height: 80),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(80, 80),
      ),
            _buildPositionedButton(
        key: 'shootButton',
        defaultPosition: Offset(20, 130),
        anchorRight: true,
        anchorBottom: true,
        child: ShootButton(width: 80, height: 80),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(80, 80),
      ),
                  _buildPositionedButton(
        key: 'goalkeeperButton',
        defaultPosition: Offset(85, 200),
        anchorRight: true,
        anchorBottom: true,
        child: GoalkeeperButton(width: 80, height: 80),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(80, 80),
      ),
                  _buildPositionedButton(
        key: 'lbButton',
        defaultPosition: Offset(0, 0),
        child: LBButton(width: 200, height: 60),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(200, 60),
      ),
                  _buildPositionedButton(
        key: 'rbButton',
        defaultPosition: Offset(0, 0),
        anchorRight: true,
        child: RBButton(width: 200, height: 60),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(200, 60),
      ),
                  _buildPositionedButton(
        key: 'ltButton',
        defaultPosition: Offset(0, 70),
        child: LTButton(width: 200, height: 60),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(200, 60),
      ),
        _buildPositionedButton(
        key: 'rtButton',
        defaultPosition: Offset(0, 70),
        anchorRight: true,
        child: RTButton(width: 200, height: 60),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(200, 60),
      ),
        _buildPositionedButton(
        key: 'dpadButton',
        defaultPosition: Offset(250, 55),
        anchorBottom: true,
        child: DPadButton(),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(100, 100),
      ),
        _buildPositionedButton(
        key: 'rightJoystickButton',
        defaultPosition: Offset(210, 30),
        anchorRight: true,
        anchorBottom: true,
        child: RightJoystickButton(width: 150,),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(150, 150),
      ),
              _buildPositionedButton(
        key: 'leftJoystickButton',
        defaultPosition: Offset(20, 20),
        anchorBottom: true,
        child: LeftJoystickButton(),
        screenSize: screenSize,
        editMode: buttonPositionProvider.editMode,
        buttonSize: Size(200, 200),
      ),
       // Adjusted select and start buttons aligned at center.
Positioned(
  top: 100, // Adjust this value as needed.
  left: 0,
  right: 0,
  child: Align(
    alignment: Alignment.center,
    child: Container(
      width: 170,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SelectButton(),
          SizedBox(width: 30),
          StartButton(),
        ],
      ),
    ),
  ),
),


        // Through Button
        // Sprint Button
        // Pass Button
        // Shoot Button
        // Goalkeeper Button
        // Left Bumper (LB)
        // Right Bumper (RB)
        // Left Trigger (LT)
        // Right Trigger (RT)
        // D-Pad Button
        // Right Joystick Button
        // Left Joystick Button
        // Select and Start Buttons.

      ],
    );
  }





void showServerSelectionDialog(List<String> servers) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Select a Server"),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(servers[index]),
                onTap: () {
                  List<String> parts = servers[index].split(':');
                  ipController.text = parts[0];
                  portController.text = parts[1];
                  // Initiate connection
                  connectionProvider.connect(parts[0], parts[1]);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
        ],
      );
    },
  );
}

Widget _buildPositionedButton({
  required String key,
  required Offset defaultPosition,
  required Widget child,
  required Size screenSize,
  required bool editMode,
  required Size buttonSize,
  bool anchorRight = false,
  bool anchorBottom = false,
}) {
  return Consumer<ButtonPositionProvider>(
    builder: (context, provider, _) {
      final position = provider.positions[key] ?? defaultPosition;
      
      // For right/bottom anchored buttons, the stored position represents
      // the distance from the right/bottom edges
      double left = anchorRight 
          ? screenSize.width - position.dx - buttonSize.width 
          : position.dx;
          
      double top = anchorBottom 
          ? screenSize.height - position.dy - buttonSize.height 
          : position.dy;

      return Positioned(
        left: left,
        top: top,
        child: editMode
            ? GestureDetector(
                onPanUpdate: (details) {
                  Offset newPosition;
                  if (anchorRight && anchorBottom) {
                    // Convert the drag movement to right/bottom offsets
                    newPosition = Offset(
                      screenSize.width - (left + details.delta.dx + buttonSize.width),
                      screenSize.height - (top + details.delta.dy + buttonSize.height)
                    );
                  } else if (anchorRight) {
                    newPosition = Offset(
                      screenSize.width - (left + details.delta.dx + buttonSize.width),
                      position.dy + details.delta.dy
                    );
                  } else if (anchorBottom) {
                    newPosition = Offset(
                      position.dx + details.delta.dx,
                      screenSize.height - (top + details.delta.dy + buttonSize.height)
                    );
                  } else {
                    newPosition = position + details.delta;
                  }
                  
                  provider.updatePosition(
                    key,
                    newPosition,
                    screenSize,
                    buttonSize,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: IgnorePointer(
                    ignoring: true,
                    child: child,
                  ),
                ),
              )
            : child,
      );
    },
  );
}

}