import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class ShootButton extends StatefulWidget {
  final double width;
  final double height;

  const ShootButton({Key? key, this.width = 80.0, this.height = 80.0})
      : super(key: key);

  @override
  _ShootButtonState createState() => _ShootButtonState();
}

class _ShootButtonState extends State<ShootButton>
    with TickerProviderStateMixin {
  // Shot names for UI and release events:
  //   "standard_shot" for a tap,
  //   "power_shot" for a long press,
  //   "chip_shot" for an upward swipe,
  //   "finesse_shot" for a downward swipe,
  //   "stunning_shot" for a horizontal swipe.
  String? activeShot;
  // For horizontal swipes, store the actual direction ("left" or "right").
  String? horizontalDirection;

  bool isSwiping = false;
  bool _isLongPressActive = false;

  // Translation (slide) animation using an Offset.
  late AnimationController _slideController;
  Animation<Offset> _slideAnimation = AlwaysStoppedAnimation(Offset.zero);

  // Scale (press) animation.
  late AnimationController _scaleController;
  Animation<double> _scaleAnimation = AlwaysStoppedAnimation(1.0);

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Animates the translation to the given [target] Offset.
  void _animateSlide(Offset target) {
    _slideAnimation = Tween<Offset>(
      begin: _slideAnimation.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _slideController.forward(from: 0);
  }

  /// Animates the scale (press) effect to the given [targetScale].
  void _animateScale(double targetScale) {
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: targetScale,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.forward(from: 0);
  }

  /// Returns the desired scale factor for a given shot type.
  /// • For tap (standard shot) and long press (power shot), scale to 0.95.
  /// • For upward swipe (chip shot) and horizontal swipe (stunning shot), scale to 1.05.
  /// • For downward swipe (finesse shot), scale to 0.9.
  double _getScaleForAction(String action) {
    switch (action) {
      case 'standard_shot':
      case 'power_shot':
        return 0.95;
      case 'chip_shot':
      case 'stunning_shot':
        return 1.05;
      case 'finesse_shot':
        return 0.9;
      default:
        return 1.0;
    }
  }

  /// Resets the button state by sending a release action (if any) and resetting animations.
  void _resetButton(ConnectionProvider connectionProvider) {
    // If there is an active shot, send its release event.
    if (activeShot != null) {
      _sendAction('${activeShot}_released');
    }
    setState(() {
      activeShot = null;
      horizontalDirection = null;
      isSwiping = false;
      _isLongPressActive = false;
      _animateSlide(Offset.zero);
      _animateScale(1.0);
    });
  }

  /// Called when a pan gesture starts (for swipes).
  void _handlePanStart(ConnectionProvider connectionProvider) {
    setState(() {
      isSwiping = true;
      if (activeShot != null) {
        connectionProvider.sendAction('${activeShot}_released');
        activeShot = null;
        horizontalDirection = null;
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Called on tap down to trigger a standard shot immediately.
  void _handleTapDown() {
    if (!isSwiping) {
      setState(() {
        activeShot = 'standard_shot';
        _sendAction('standard_shot_pressed');
        _animateScale(_getScaleForAction('standard_shot'));
      });
    }
  }

  /// Called on long press to trigger a power shot.
  /// If a standard shot was already triggered, it first sends its release event.
  void _handleLongPress() {
    // If a standard shot was already triggered, release it.
    if (activeShot == 'standard_shot') {
      _sendAction('standard_shot_released');
    }
    setState(() {
      _isLongPressActive = true;
      activeShot = 'power_shot';
      _sendAction('power_shot_pressed');
      _animateScale(_getScaleForAction('power_shot'));
    });
  }

  /// Handles pan updates to detect swipes in any direction.
  /// The dominant direction is determined by comparing horizontal and vertical deltas.
  void _handlePanUpdate(
      DragUpdateDetails details, ConnectionProvider connectionProvider) {
    double dx = details.delta.dx;
    double dy = details.delta.dy;
    if (dy.abs() > dx.abs()) {
      // Vertical swipe is dominant.
      if (dy < -5) {
        // Upward swipe → Chip shot.
        if (activeShot != 'chip_shot') {
          setState(() {
            activeShot = 'chip_shot';
            _sendAction('chip_shot_pressed');
            _animateSlide(Offset(0, -10));
            _animateScale(_getScaleForAction('chip_shot'));
          });
        }
      } else if (dy > 5) {
        // Downward swipe → Finesse shot.
        if (activeShot != 'finesse_shot') {
          setState(() {
            activeShot = 'finesse_shot';
            _sendAction('finesse_shot_pressed');
            _animateSlide(Offset(0, 10));
            _animateScale(_getScaleForAction('finesse_shot'));
          });
        }
      }
    } else {
      // Horizontal swipe is dominant.
      if (dx > 5) {
        // Right swipe → Stunning shot.
        if (activeShot != 'stunning_shot') {
          setState(() {
            activeShot = 'stunning_shot';
            horizontalDirection = 'right';
            _sendAction('stunning_shot_pressed');
            _animateSlide(Offset(10, 0));
            _animateScale(_getScaleForAction('stunning_shot'));
          });
        } else {
          horizontalDirection = 'right';
        }
      } else if (dx < -5) {
        // Left swipe → Stunning shot.
        if (activeShot != 'stunning_shot') {
          setState(() {
            activeShot = 'stunning_shot';
            horizontalDirection = 'left';
            _sendAction('stunning_shot_pressed');
            _animateSlide(Offset(-10, 0));
            _animateScale(_getScaleForAction('stunning_shot'));
          });
        } else {
          horizontalDirection = 'left';
        }
      }
    }
  }

  /// Sends an action using the connection provider and triggers light haptic feedback.
  void _sendAction(String action) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    connectionProvider.sendAction(action);
    HapticFeedback.lightImpact();
  }

  /// Builds dynamic text widgets to display in the center of the button.
  /// - For an upward swipe (chip shot), display "Chop" above "Shoot".  
  /// - For a downward swipe (finesse shot), display "Shoot" above "Finesse".  
  /// - For a horizontal swipe (stunning shot), display "Shoot" above "Stunning".  
  /// - For tap/long press, display just "Shoot".
  List<Widget> _buildTextWidgets() {
    TextStyle mainTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    TextStyle subTextStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
    );

    if (activeShot == 'chip_shot') {
      return [
        Text("Chop", style: subTextStyle),
        Text("Shoot", style: mainTextStyle),
      ];
    } else if (activeShot == 'finesse_shot') {
      return [
        Text("Shoot", style: mainTextStyle),
        Text("Finesse", style: subTextStyle),
      ];
    } else if (activeShot == 'stunning_shot') {
      return [
        Text("Shoot", style: mainTextStyle),
        Text("Stunning", style: subTextStyle),
      ];
    } else if (activeShot == 'standard_shot' || activeShot == 'power_shot') {
      return [
        Text("Shoot", style: mainTextStyle),
      ];
    } else {
      return [
        Text("Shoot", style: mainTextStyle),
      ];
    }
  }

  /// Builds the visual appearance of the button.
  /// Four fixed arrow icons are placed at the edges.
  /// Their opacity is increased (set to 1.0) if that directional action is active.
  /// For horizontal swipes, the left or right arrow is highlighted based on [horizontalDirection].
  Widget _buildButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
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
          // Top arrow: highlighted if activeShot is "chip_shot" (upward swipe).
          Positioned(
            top: 8,
            child: Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white.withOpacity(activeShot == 'chip_shot' ? 1.0 : 0.7),
              size: 16,
            ),
          ),
          // Bottom arrow: highlighted if activeShot is "finesse_shot" (downward swipe).
          Positioned(
            bottom: 8,
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(activeShot == 'finesse_shot' ? 1.0 : 0.7),
              size: 16,
            ),
          ),
          // Left arrow: highlighted if activeShot is "stunning_shot" and horizontalDirection is "left".
          Positioned(
            left: 8,
            child: Icon(
              Icons.keyboard_arrow_left,
              color: Colors.white.withOpacity(
                  (activeShot == 'stunning_shot' && horizontalDirection == 'left')
                      ? 1.0
                      : 0.7),
              size: 16,
            ),
          ),
          // Right arrow: highlighted if activeShot is "stunning_shot" and horizontalDirection is "right".
          Positioned(
            right: 8,
            child: Icon(
              Icons.keyboard_arrow_right,
              color: Colors.white.withOpacity(
                  (activeShot == 'stunning_shot' && horizontalDirection == 'right')
                      ? 1.0
                      : 0.7),
              size: 16,
            ),
          ),
          // Central dynamic text area.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildTextWidgets(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    return GestureDetector(
      // Pan gestures for swiping.
      onPanStart: (_) => _handlePanStart(connectionProvider),
      onPanUpdate: (details) => _handlePanUpdate(details, connectionProvider),
      onPanEnd: (_) => _resetButton(connectionProvider),
      onPanCancel: () => _resetButton(connectionProvider),
      // Tap and long-press for standard/power shot.
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _resetButton(connectionProvider),
      onTapCancel: () => _resetButton(connectionProvider),
      onLongPress: _handleLongPress,
      onLongPressUp: () => _resetButton(connectionProvider),
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
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
