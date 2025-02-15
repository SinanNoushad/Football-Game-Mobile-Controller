// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
// import '../providers/connection_provider.dart';

// class PassButton extends StatelessWidget {
//   final double width;
//   final double height;
//   String? activeShot; // To track the current swipe action

//   PassButton({this.width = 80.0, this.height = 80.0});

//   @override
//   Widget build(BuildContext context) {
//     final connectionProvider =
//     Provider.of<ConnectionProvider>(context, listen: false);

//     return GestureDetector(
//       onTapDown: (_) {
//         connectionProvider.sendAction('short_pass_pressed');
//         HapticFeedback.lightImpact();
//       },
//       onTapUp: (_) {
//         connectionProvider.sendAction('short_pass_released');
//         HapticFeedback.lightImpact();
//         },
//       onTapCancel: () {
//         connectionProvider.sendAction('short_pass_released');
//         HapticFeedback.lightImpact();
//       },
//       onVerticalDragUpdate: (details) {
//         double dy = details.delta.dy;

//         if (dy < -5 && activeShot != 'lobbed_through_ball') {
//           connectionProvider.sendAction('lobbed_through_ball_pressed');
//           HapticFeedback.heavyImpact();
//           activeShot = 'lobbed_through_ball';
//         }
//       },
//       onVerticalDragEnd: (details) {
//         if (activeShot != null) {
//           connectionProvider.sendAction('${activeShot}_released');
//           activeShot = null;
//         }
//       },


//       // onLongPress: () {
//       //   bool success = connectionProvider.sendAction('long_pass');
//       //   if (success) {
//       //     HapticFeedback.mediumImpact();
//       //   } else {
//       //     ScaffoldMessenger.of(context).showSnackBar(
//       //       SnackBar(content: Text('Not connected to server. Please connect to send actions.')),
//       //     );
//       //   }
//       // },
//       // onVerticalDragUpdate: (details) {
//       //   if (details.delta.dy < -5) {
//       //     connectionProvider.sendAction('lofted_pass'); // Swipe Up
//       //     HapticFeedback.heavyImpact();
//       //   } else if (details.delta.dy > 5) {
//       //     connectionProvider.sendAction('driven_pass'); // Swipe Down
//       //     HapticFeedback.heavyImpact();
//       //   }
//       // },
//       // onHorizontalDragUpdate: (details) {
//       //   if (details.delta.dx < -5) {
//       //     connectionProvider.sendAction('precision_pass_left'); // Swipe Left
//       //     HapticFeedback.selectionClick();
//       //   } else if (details.delta.dx > 5) {
//       //     connectionProvider.sendAction('precision_pass_right'); // Swipe Right
//       //     HapticFeedback.selectionClick();
//       //   }
//       // },

//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.blueAccent,
//           shape: BoxShape.circle,
//         ),
//         child: Center(
//           child: Text(
//             'Pass',
//             style: TextStyle(color: Colors.white, fontSize: 16),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class PassButton extends StatefulWidget {
  final double width;
  final double height;

  const PassButton({Key? key, this.width = 80.0, this.height = 80.0})
      : super(key: key);

  @override
  _PassButtonState createState() => _PassButtonState();
}

class _PassButtonState extends State<PassButton> with TickerProviderStateMixin {
  // This variable tracks which action is active:
  // - 'short_pass' for a tap, or
  // - 'lobbed_through_ball' for an upward swipe.
  String? activeShot;
  bool isSwiping = false;
  bool _isLongPressActive = false; // (kept in case you later add long-press logic)

  // Animation controllers for vertical slide and press (scale) effects.
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _pressController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  /// Animates the vertical slide (translation) to the [targetValue].
  void _animateSlide(double targetValue) {
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: targetValue,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _slideController.forward(from: 0);
  }

  /// Animates the press (scale) effect to the [targetScale].
  void _animatePress(double targetScale) {
    _pressAnimation = Tween<double>(
      begin: _pressAnimation.value,
      end: targetScale,
    ).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _pressController.forward(from: 0);
  }

  /// Returns the desired scale for a given action.
  /// • 'short_pass' scales to 0.95  
  /// • 'lobbed_through_ball' scales to 1.05  
  double _getPressScaleForAction(String action) {
    switch (action) {
      case 'short_pass':
        return 0.95;
      case 'lobbed_through_ball':
        return 1.05;
      default:
        return 1.0;
    }
  }

  /// Resets the button state by sending the release event (if any)
  /// and resetting animations and flags.
  void _resetButton(ConnectionProvider connectionProvider) {
    if (activeShot != null) {
      _sendAction('${activeShot}_released');
    }
    setState(() {
      activeShot = null;
      isSwiping = false;
      _isLongPressActive = false;
      _animateSlide(0);
      _animatePress(1.0);
    });
  }

  /// Called when a pan (swipe) gesture starts.
  /// This cancels any tap action and sets the swipe flag.
  void _handlePanStart(ConnectionProvider connectionProvider) {
    setState(() {
      isSwiping = true;
      if (activeShot != null) {
        connectionProvider.sendAction('${activeShot}_released');
        activeShot = null;
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Called immediately on tap down.
  /// (No delay—action is triggered as soon as the finger touches the button.)
  void _handleTapDown() {
    if (!isSwiping) {
      setState(() {
        activeShot = 'short_pass';
        _sendAction('short_pass_pressed');
        _animatePress(_getPressScaleForAction('short_pass'));
      });
    }
  }

  /// Called during a vertical drag.
  /// If an upward swipe is detected, trigger the "lobbed_through_ball" action.
  void _handleVerticalDrag(DragUpdateDetails details, ConnectionProvider connectionProvider) {
    double dy = details.delta.dy;
    if (dy < -2) {
      setState(() {
        if (activeShot != 'lobbed_through_ball') {
          activeShot = 'lobbed_through_ball';
          _sendAction('lobbed_through_ball_pressed');
          _animateSlide(-10); // Slide upward slightly.
          _animatePress(_getPressScaleForAction('lobbed_through_ball'));
        }
      });
    }
  }

  /// Builds the dynamic text display.
  /// If the active action is a lobbed pass, it shows "Lob" above "Pass";
  /// otherwise, it shows just "Pass".
  List<Widget> _buildTextWidgets() {
    TextStyle mainTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      shadows: [
        Shadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
    if (activeShot == 'lobbed_through_ball') {
      return [
        Text("Lob", style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text("Pass", style: mainTextStyle),
      ];
    } else {
      return [ Text("Pass", style: mainTextStyle) ];
    }
  }

  /// Builds the visual appearance of the button.
  Widget _buildButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1976D2).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fixed up-arrow indicator.
          Positioned(
            top: 8,
            child: Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ),
          // Dynamic text.
          Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildTextWidgets(),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to send actions via the connection provider and trigger haptic feedback.
  void _sendAction(String action) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    connectionProvider.sendAction(action);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    return GestureDetector(
      onPanStart: (_) => _handlePanStart(connectionProvider),
      onPanEnd: (_) => _resetButton(connectionProvider),
      onPanCancel: () => _resetButton(connectionProvider),
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _resetButton(connectionProvider),
      onTapCancel: () => _resetButton(connectionProvider),
      onVerticalDragUpdate: (details) =>
          _handleVerticalDrag(details, connectionProvider),
      onVerticalDragEnd: (_) => _resetButton(connectionProvider),
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: AnimatedBuilder(
              animation: _pressAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pressAnimation.value,
                  child: _buildButton(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
