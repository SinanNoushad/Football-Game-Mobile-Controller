import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class DPadButton extends StatelessWidget {
  final double width;
  final double height;
  final Color buttonColor;
  final double buttonSize;


  const DPadButton({
    Key? key,
    this.width = 150.0,
    this.height = 150.0,
    this.buttonColor = Colors.black87, // Change button color here
    this.buttonSize = 50.0, // Adjust button size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);


    return Container(
      width: width,
      height: height,
        decoration: BoxDecoration(
          color: buttonColor, // Background color
            shape: BoxShape.circle, // Circular shape
        ),
        child: FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          IconButton(
            icon: Icon(Icons.arrow_drop_up, color: Colors.white, size: width * 1),
            onPressed: () => connectionProvider.sendAction('dpad_up'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left,color: Colors.white, size: width * 1),
                onPressed: () => connectionProvider.sendAction('dpad_left'),
              ),
              SizedBox(width: width * 1),
              IconButton(
                icon: Icon(Icons.arrow_right,color: Colors.white, size: width * 1),
                onPressed: () => connectionProvider.sendAction('dpad_right'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.arrow_drop_down,color: Colors.white, size: width * 1),
            onPressed: () => connectionProvider.sendAction('dpad_down'),
          ),
        ],
      ),
        )
    );
  }
}