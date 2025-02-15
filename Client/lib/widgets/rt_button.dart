import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import 'package:flutter/services.dart';

class RTButton extends StatelessWidget {
  final double width;
  final double height;

  RTButton({this.width = 70.0, this.height = 70.0});

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
    Provider.of<ConnectionProvider>(context, listen: false);

    return GestureDetector(
      onTapDown: (_) {
        connectionProvider.sendAction('right_trigger_pressed');
        HapticFeedback.lightImpact();
        },
      onTapUp: (_) {
        connectionProvider.sendAction('right_trigger_released');
        HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        connectionProvider.sendAction('right_trigger_released');
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'RT',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
