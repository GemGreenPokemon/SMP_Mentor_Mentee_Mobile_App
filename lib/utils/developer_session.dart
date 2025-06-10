import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the Developer Mode session is active with persistence.
class DeveloperSession {
  static bool _isActive = false;
  static const String _keyDeveloperMode = 'developer_mode_active';
  
  /// Get the current developer session state
  static bool get isActive => _isActive;
  
  /// Initialize the developer session from saved state
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isActive = prefs.getBool(_keyDeveloperMode) ?? false;
      print('🔧 DeveloperSession: Initialized with isActive = $_isActive');
    } catch (e) {
      print('🔧 DeveloperSession: Failed to initialize, defaulting to false: $e');
      _isActive = false;
    }
  }
  
  /// Enable developer mode with persistence
  static Future<void> enable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDeveloperMode, true);
      _isActive = true;
      print('🔧 DeveloperSession: Enabled and saved to preferences');
    } catch (e) {
      print('🔧 DeveloperSession: Failed to save enabled state: $e');
      _isActive = true; // Still enable in memory
    }
  }
  
  /// Disable developer mode with persistence
  static Future<void> disable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDeveloperMode, false);
      _isActive = false;
      print('🔧 DeveloperSession: Disabled and saved to preferences');
    } catch (e) {
      print('🔧 DeveloperSession: Failed to save disabled state: $e');
      _isActive = false; // Still disable in memory
    }
  }
  
  /// Clear all developer session data
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDeveloperMode);
      _isActive = false;
      print('🔧 DeveloperSession: Cleared from preferences');
    } catch (e) {
      print('🔧 DeveloperSession: Failed to clear preferences: $e');
      _isActive = false;
    }
  }
}
