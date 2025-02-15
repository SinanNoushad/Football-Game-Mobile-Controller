// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
// import '../providers/connection_provider.dart';

// class GoalkeeperButton extends StatelessWidget {
//   final double width;
//   final double height;

//   GoalkeeperButton({this.width = 80.0, this.height = 80.0});

//   @override
//   Widget build(BuildContext context) {
//     final connectionProvider = 
//         Provider.of<ConnectionProvider>(context, listen: false);

//     return GestureDetector(
//       onTapDown: (_) {
//         connectionProvider.sendAction('goalkeeper_pressed');
//         HapticFeedback.mediumImpact();
//       },
//       onTapUp: (_) {
//         connectionProvider.sendAction('goalkeeper_released');
//         HapticFeedback.mediumImpact();
//       },
//       onTapCancel: () {
//         connectionProvider.sendAction('goalkeeper_released');
//         HapticFeedback.mediumImpact();
//       },
//       // child: Container(
//       //   width: width,
//       //   height: height,
//       //   decoration: BoxDecoration(
//       //     color: const Color.fromARGB(255, 183, 41, 234),  // Different color to distinguish from pass button
//       //     shape: BoxShape.circle,
//       //   ),
//       //   child: Center(
//       //     child: Text(
//       //       'GK',
//       //       style: TextStyle(color: Colors.white, fontSize: 16),
//       //     ),
//       //   ),
//       // ),
//       child: Container(
//   width: 60,
//   height:60,
//   decoration: BoxDecoration(
//     gradient: LinearGradient(
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//       colors: [
//         const Color.fromARGB(255, 183, 41, 234),
//         const Color.fromARGB(255, 156, 39, 198),
//       ],
//     ),
//     shape: BoxShape.circle,
//     boxShadow: [
//       BoxShadow(
//         color: const Color.fromARGB(255, 183, 41, 234).withOpacity(0.3),
//         spreadRadius: 2,
//         blurRadius: 8,
//         offset: const Offset(0, 4),
//       ),
//     ],
//     border: Border.all(
//       color: Colors.white.withOpacity(0.2),
//       width: 1.5,
//     ),
//   ),
//   child: Center(
//     child: Container(
//       padding: const EdgeInsets.all(8.0),
//       child: const Text(
//         'GK',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 1.2,
//           shadows: [
//             Shadow(
//               color: Colors.black26,
//               offset: Offset(0, 2),
//               blurRadius: 4,
//             ),
//           ],
//         ),
//       ),
//     ),
//   ),
// )
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class GoalkeeperButton extends StatefulWidget {
  final double width;
  final double height;

  const GoalkeeperButton({Key? key, this.width = 80.0, this.height = 80.0})
      : super(key: key);

  @override
  _GoalkeeperButtonState createState() => _GoalkeeperButtonState();
}

class _GoalkeeperButtonState extends State<GoalkeeperButton> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      reverseDuration: Duration(milliseconds: 100),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(ConnectionProvider connectionProvider) {
    connectionProvider.sendAction('goalkeeper_rush_pressed');
    HapticFeedback.mediumImpact();
    _pressController.forward();
  }

  void _handleTapUp(ConnectionProvider connectionProvider) {
    connectionProvider.sendAction('goalkeeper_rush_released');
    HapticFeedback.mediumImpact();
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(connectionProvider),
      onTapUp: (_) => _handleTapUp(connectionProvider),
      onTapCancel: () => _handleTapUp(connectionProvider),
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 183, 41, 234),
                    const Color.fromARGB(255, 156, 39, 198),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 183, 41, 234).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    'GK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
