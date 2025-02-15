import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ButtonPositionProvider extends ChangeNotifier {
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _defaultPositions;
  bool _editMode = false;

  ButtonPositionProvider(this._defaultPositions) {
    _loadPositions();
  }

  bool get editMode => _editMode;
  Map<String, Offset> get positions => _positions;

  void _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultPositions.forEach((key, defaultValue) {
      final x = prefs.getDouble('${key}X') ?? defaultValue.dx;
      final y = prefs.getDouble('${key}Y') ?? defaultValue.dy;
      _positions[key] = Offset(x, y);
    });
    notifyListeners();
  }

  void updatePosition(String key, Offset newPosition, Size screenSize, Size buttonSize) {
    final maxX = screenSize.width - buttonSize.width;
    final maxY = screenSize.height - buttonSize.height;
    
    _positions[key] = Offset(
      newPosition.dx.clamp(0.0, maxX),
      newPosition.dy.clamp(0.0, maxY),
    );
    notifyListeners();
  }

  void savePositions() async {
    final prefs = await SharedPreferences.getInstance();
    _positions.forEach((key, position) {
      prefs.setDouble('${key}X', position.dx);
      prefs.setDouble('${key}Y', position.dy);
    });
  }

  void toggleEditMode() {
    _editMode = !_editMode;
    if (!_editMode) savePositions();
    notifyListeners();
  }
}