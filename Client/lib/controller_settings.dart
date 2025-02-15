import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ControllerSettings {
  static const _keyName = 'controllerName';
  static const _keyId = 'controllerId';

  /// Returns the saved controller name or null if none is set.
  static Future<String?> getControllerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  /// Saves the controller name.
  static Future<void> setControllerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  /// Returns the unique controller ID. Generates one if it doesn't exist.
  static Future<String> getControllerId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyId);
    if (id == null) {
      id = Uuid().v4();
      await prefs.setString(_keyId, id);
    }
    return id;
  }
}
