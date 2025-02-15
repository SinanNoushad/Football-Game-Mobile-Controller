import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class StartButton extends StatelessWidget {
  final double size; // Size of the circular button
  final IconData icon; // Icon to display inside the button

  const StartButton({
    Key? key,
    this.size = 50.0, // Default size of the button
    this.icon = Icons.power_settings_new, // Default icon (can be changed)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return GestureDetector(
      onTapDown: (_) => connectionProvider.sendAction('start_pressed'),
      onTapUp: (_) => connectionProvider.sendAction('start_released'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300], // Button color
          shape: BoxShape.circle, // Makes the button circular
          boxShadow: [
            BoxShadow(
              color: Colors.black26, // Adds a subtle shadow
              blurRadius: 5,
              spreadRadius: 1,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.black,
            size: size * 0.8, // Icon size is half of button size
          ),
        ),
      ),
    );
  }
}
