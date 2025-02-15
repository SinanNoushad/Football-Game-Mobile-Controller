import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class RightJoystickButton extends StatelessWidget {
  final double width;
  final double height;

  const RightJoystickButton({
    Key? key,
    this.width = 200.0,
    this.height = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Joystick(
      listener: (details) {
        connectionProvider.sendAction(
          'camera_${details.x.toStringAsFixed(2)}_${details.y.toStringAsFixed(2)}',
        );
      },
      onStickDragEnd: () {
        // Send 0,0 when joystick is released
        connectionProvider.sendAction('move_0_0');
      },
    base: JoystickBase(
        size: 150,
        decoration: JoystickBaseDecoration(
          color: Colors.black,
          drawOuterCircle: false,
        ),
        arrowsDecoration: JoystickArrowsDecoration(
          color: Colors.blue,
        ),
      ),
    stick: JoystickStick(
        size: width / 2,
        decoration: JoystickStickDecoration(
          color: Colors.blue,
        ),
      ),
    );
  }
}


