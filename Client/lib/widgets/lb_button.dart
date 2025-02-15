import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import 'package:flutter/services.dart';

class LBButton extends StatelessWidget {
  final double width;
  final double height;

  LBButton({this.width = 60.0, this.height = 60.0});

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
    Provider.of<ConnectionProvider>(context, listen: false);

    return GestureDetector(
      onTapDown: (_) {
        connectionProvider.sendAction('left_bumper_pressed');
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        connectionProvider.sendAction('left_bumper_released');
        HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        connectionProvider.sendAction('left_bumper_released');
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
            'LB',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
