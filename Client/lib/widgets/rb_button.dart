import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import 'package:flutter/services.dart';

class RBButton extends StatelessWidget {
  final double width;
  final double height;

  RBButton({this.width = 60.0, this.height = 60.0});

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
    Provider.of<ConnectionProvider>(context, listen: false);

    return GestureDetector(
      onTapDown: (_) {
        connectionProvider.sendAction('right_bumper_pressed');
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        connectionProvider.sendAction('right_bumper_released');
        HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        connectionProvider.sendAction('right_bumper_released');
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'RB',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
