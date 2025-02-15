import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/connection_provider.dart';

class SprintButton extends StatefulWidget {
  final double width;
  final double height;

  const SprintButton({Key? key, this.width = 80.0, this.height = 80.0})
      : super(key: key);

  @override
  _SprintButtonState createState() => _SprintButtonState();
}

class _SprintButtonState extends State<SprintButton>
    with TickerProviderStateMixin {
  String? activeShot;
  bool isSwiping = false;
  Timer? _tapTimer;
  bool _isLongPressActive = false;

  // Animation controller for vertical translation (in pixels).
  late AnimationController _slideController;
  Animation<double> _slideAnimation = AlwaysStoppedAnimation(0);

  // Animation controller for scale (press effect).
  late AnimationController _pressController;
  Animation<double> _pressAnimation = AlwaysStoppedAnimation(1.0);

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
    _tapTimer?.cancel();
    _slideController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  /// Animates the vertical translation to the given [targetValue] (in pixels).
  void _animateSlide(double targetValue) {
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: targetValue,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _slideController.forward(from: 0);
  }

  /// Animates the scale (press) effect to the given [targetScale].
  void _animatePress(double targetScale) {
    _pressAnimation = Tween<double>(
      begin: _pressAnimation.value,
      end: targetScale,
    ).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _pressController.forward(from: 0);
  }

  /// Returns a scale factor based on the given action.
  /// For a normal sprint (tap) or long sprint, scale to 0.95.
  /// For a downward swipe (to switch players), also scale to 0.95.
  double _getPressScaleForAction(String action) {
    switch (action) {
      case 'start_sprint':
      case 'long_sprint_pressed':
      case 'Switch_player':
        return 0.95;
      default:
        return 1.0;
    }
  }

  /// Resets the button state by sending a release action (if any) and resetting animations.
  void _resetButton(ConnectionProvider connectionProvider) {
    _tapTimer?.cancel();
    _tapTimer = null;
    
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

  /// Called when a pan gesture starts.
  void _handlePanStart(ConnectionProvider connectionProvider) {
    _tapTimer?.cancel();
    setState(() {
      isSwiping = true;
      if (activeShot != null) {
        connectionProvider.sendAction('${activeShot}_released');
        activeShot = null;
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Called on tap down to trigger a sprint immediately.
  void _handleTapDown() {
    if (!isSwiping && activeShot != 'start_sprint') {
      setState(() {
        activeShot = 'start_sprint';
        _sendAction('start_sprint_pressed');
        _animatePress(_getPressScaleForAction('start_sprint'));
      });
    }
  }

  /// Called on vertical drag update.
  /// If the user drags downward (dy > 5), trigger the "Switch_player" action.
  void _handleVerticalDragUpdate(
      DragUpdateDetails details, ConnectionProvider connectionProvider) {
    double dy = details.delta.dy;
    if (dy > 5) {
      setState(() {
        if (activeShot != 'Switch_player') {
          activeShot = 'Switch_player';
          _sendAction('Switch_player_pressed');
          _animateSlide(10); // Move downward slightly.
          _animatePress(_getPressScaleForAction('Switch_player'));
        }
      });
    }
  }

  /// Builds dynamic text widgets based on the active action.
  /// If activeShot is "Switch_player", shows "Sprint" above "Switch".
  /// Otherwise, shows just "Sprint".
  List<Widget> _buildTextWidgets() {
    TextStyle mainTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    TextStyle subTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
    );
    if (activeShot == 'Switch_player') {
      return [
        Text("Sprint", style: mainTextStyle),
        Text("Switch", style: subTextStyle),
      ];
    } else {
      return [
        Text("Sprint", style: mainTextStyle),
      ];
    }
  }

  /// Builds the visual appearance of the SprintButton.
  /// In addition to dynamic text, a keyboard arrow icon is added at the bottom.
  Widget _buildButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 16, 178, 100),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fixed down-arrow indicator.
          Positioned(
            bottom: 8,
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
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

  /// Sends an action using the connection provider and triggers light haptic feedback.
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
          _handleVerticalDragUpdate(details, connectionProvider),
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
