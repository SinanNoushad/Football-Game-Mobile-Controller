// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
// import '../providers/connection_provider.dart';

// class ThroughButton extends StatefulWidget {
//   final double width;
//   final double height;

//   ThroughButton({this.width = 80.0, this.height = 80.0});

//   @override
//   _ThroughButtonState createState() => _ThroughButtonState();
// }

// class _ThroughButtonState extends State<ThroughButton> {
//   String? activeShot;
//   bool isSwiping = false;
//   Timer? _tapTimer;
//   bool _isLongPressActive = false;

//   @override
//   void dispose() {
//     _tapTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

//     return GestureDetector(
//       onPanStart: (_) {
//         _handlePanStart(connectionProvider);
//       },
//       onPanEnd: (_) => setState(() => isSwiping = false),
//       onPanCancel: () => setState(() => isSwiping = false),
      
//       onTapDown: (_) => _handleTapDown(),
//       onTapUp: (_) => _handleTapUp(connectionProvider),
//       onTapCancel: () => _handleTapCancel(connectionProvider),

//       onVerticalDragUpdate: (details) => _handleVerticalDrag(details, connectionProvider),
//       onVerticalDragEnd: (_) => _handleVerticalDragEnd(connectionProvider),

//       child: _buildButton(),
//     );
//   }

//   void _handlePanStart(ConnectionProvider connectionProvider) {
//     _tapTimer?.cancel();
//     setState(() {
//       isSwiping = true;
//       if (activeShot != null) {
//         connectionProvider.sendAction('${activeShot}_released');
//         activeShot = null;
//         HapticFeedback.lightImpact();
//       }
//     });
//   }

//   void _handleTapDown() {
//     if (!isSwiping) {
//       _tapTimer = Timer(Duration(milliseconds: 200), () {
//         if (!_isLongPressActive && activeShot != 'standard_through_ball') {
//           setState(() {
//             activeShot = 'standard_through_ball';
//             _sendAction('standard_through_ball_pressed');
//           });
//         }
//       });
//     }
//   }

//   void _handleTapUp(ConnectionProvider connectionProvider) {
//     _tapTimer?.cancel();
//     if (activeShot == 'standard_through_ball' && !_isLongPressActive) {
//       setState(() {
//         _sendAction('standard_through_ball_released');
//         activeShot = null;
//       });
//     }
//   }

//   void _handleTapCancel(ConnectionProvider connectionProvider) {
//     _tapTimer?.cancel();
//     if (activeShot == 'standard_through_ball' && !_isLongPressActive) {
//       setState(() {
//         _sendAction('standard_through_ball_released');
//         activeShot = null;
//       });
//     }
//   }

//   void _handleVerticalDrag(DragUpdateDetails details, ConnectionProvider connectionProvider) {
//     double dy = details.delta.dy;
//     if (dy.abs() > 2) {
//       setState(() {
//         final action = dy > 2 ? 'hard_slide_tackle' : 'lobbed_through_ball';
//         if (activeShot != action) {
//           activeShot = action;
//           _sendAction('${action}_pressed');
//         }
//       });
//     }
//   }

//   void _handleVerticalDragEnd(ConnectionProvider connectionProvider) {
//     if (activeShot != null) {
//       setState(() {
//         _sendAction('${activeShot}_released');
//         activeShot = null;
//       });
//     }
//   }

//   Widget _buildButton() {
//     return Container(
//       width: widget.width,
//       height: widget.height,
//       decoration: BoxDecoration(
//         color: Colors.orangeAccent,
//         shape: BoxShape.circle,
//       ),
//       child: Center(
//         child: Text(
//           'Through',
//           style: TextStyle(color: Colors.white, fontSize: 16),
//         ),
//       ),
//     );
//   }

//   void _sendAction(String action) {
//     final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
//     connectionProvider.sendAction(action);
//     HapticFeedback.lightImpact();
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class ThroughButton extends StatefulWidget {
  final double width;
  final double height;

  ThroughButton({this.width = 80.0, this.height = 80.0});

  @override
  _ThroughButtonState createState() => _ThroughButtonState();
}

class _ThroughButtonState extends State<ThroughButton>
    with TickerProviderStateMixin {
  String? activeShot;
  bool isSwiping = false;
  bool _isLongPressActive = false;

  // Slide animation controller and animation.
  late AnimationController _animationController;
  Animation<double> _slideAnimation = AlwaysStoppedAnimation(0);

  // Press animation controller and animation.
  late AnimationController _pressController;
  Animation<double> _pressAnimation = AlwaysStoppedAnimation(1.0);

  @override
  void initState() {
    super.initState();
    // Slide animation controller.
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Press animation controller.
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
    _animationController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  /// Animates vertical slide (translation).
  void _animateSlide(double targetValue) {
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: targetValue,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(from: 0);
  }

  /// Animates the press (scale) effect.
  void _animatePress(double targetScale) {
    _pressAnimation = Tween<double>(
      begin: _pressAnimation.value,
      end: targetScale,
    ).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _pressController.forward(from: 0);
  }

  /// Returns a scale factor based on the active action.
  double _getPressScaleForAction(String action) {
    switch (action) {
      case 'standard_through_ball':
        return 0.95;
      case 'lobbed_through_ball':
        return 1.05;
      case 'hard_slide_tackle':
        return 0.9;
      default:
        return 1.0;
    }
  }

  /// Resets the button state: sends a release action, resets the slide and press animations.
  void _resetButton(ConnectionProvider connectionProvider) {
    if (activeShot != null) {
      _sendAction('${activeShot}_released');
    }
    setState(() {
      activeShot = null;
      isSwiping = false;
      _animateSlide(0);
      _animatePress(1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);

    return GestureDetector(
      // Gesture start.
      onPanStart: (_) {
        _handlePanStart(connectionProvider);
      },
      // Gesture end.
      onPanEnd: (_) {
        _resetButton(connectionProvider);
      },
      onPanCancel: () {
        _resetButton(connectionProvider);
      },
      // Tap events.
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _resetButton(connectionProvider),
      onTapCancel: () => _resetButton(connectionProvider),
      // Vertical drag events.
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

  void _handlePanStart(ConnectionProvider connectionProvider) {
    setState(() {
      isSwiping = true;
      // If an action is already active, release it.
      if (activeShot != null) {
        connectionProvider.sendAction('${activeShot}_released');
        activeShot = null;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _handleTapDown() {
    if (!isSwiping) {
      setState(() {
        activeShot = 'standard_through_ball';
        _sendAction('standard_through_ball_pressed');
        _animatePress(_getPressScaleForAction('standard_through_ball'));
      });
    }
  }

  void _handleVerticalDrag(
      DragUpdateDetails details, ConnectionProvider connectionProvider) {
    double dy = details.delta.dy;
    if (dy.abs() > 2) {
      setState(() {
        // When swiping down, choose 'hard_slide_tackle'; when swiping up, choose 'lobbed_through_ball'
        final action = dy > 2 ? 'hard_slide_tackle' : 'lobbed_through_ball';
        if (activeShot != action) {
          activeShot = action;
          _sendAction('${action}_pressed');
          _animateSlide(dy > 2 ? 10 : -10);
          _animatePress(_getPressScaleForAction(action));
        }
      });
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'lobbed_through_ball':
        return 'Lob';
      case 'hard_slide_tackle':
        return 'Slide';
      case 'standard_through_ball':
        return 'Standard';
      default:
        return '';
    }
  }

  /// Returns the text widgets arranged according to the swipe direction.
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

    TextStyle subTextStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );

    if (activeShot == 'lobbed_through_ball') {
      // When swiping up, display the action text (e.g. "Lob") above the main label.
      return [
        Text(_getActionText(activeShot!), style: subTextStyle),
        Text('Through', style: mainTextStyle),
      ];
    } else if (activeShot == 'hard_slide_tackle') {
      // When swiping down, display the main label above the action text.
      return [
        Text('Through', style: mainTextStyle),
        Text(_getActionText(activeShot!), style: subTextStyle),
      ];
    } else {
      // Default state.
      return [
        Text('Through', style: mainTextStyle),
      ];
    }
  }

  Widget _buildButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9D2F),
            Color(0xFFFF6B00),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6B00).withOpacity(0.3),
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
          // Fixed swipe indicators.
          Positioned(
            top: 8,
            child: Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 8,
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ),
          // Dynamic text area.
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

  void _sendAction(String action) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    connectionProvider.sendAction(action);
    HapticFeedback.lightImpact();
  }
}