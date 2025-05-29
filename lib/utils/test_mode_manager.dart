import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class TestModeManager {
  static const String _testModeKey = 'test_mode_enabled';
  static const String _testUserIdKey = 'test_user_id';
  static const String _testUserNameKey = 'test_user_name';
  static const String _testUserTypeKey = 'test_user_type';
  static const String _testUserEmailKey = 'test_user_email';
  
  static bool _isTestMode = false;
  static User? _currentTestUser;
  
  static bool get isTestMode => _isTestMode;
  static User? get currentTestUser => _currentTestUser;
  
  // Initialize test mode from SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isTestMode = prefs.getBool(_testModeKey) ?? false;
    
    if (_isTestMode) {
      final userId = prefs.getString(_testUserIdKey);
      if (userId != null) {
        // Reconstruct basic user info from preferences
        _currentTestUser = User(
          id: userId,
          name: prefs.getString(_testUserNameKey) ?? 'Test User',
          email: prefs.getString(_testUserEmailKey) ?? 'test@example.com',
          userType: prefs.getString(_testUserTypeKey) ?? 'mentor',
          createdAt: DateTime.now(),
        );
      }
    }
  }
  
  // Enable test mode with a specific user
  static Future<void> enableTestMode(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    _isTestMode = true;
    _currentTestUser = user;
    
    // Save to preferences
    await prefs.setBool(_testModeKey, true);
    await prefs.setString(_testUserIdKey, user.id);
    await prefs.setString(_testUserNameKey, user.name);
    await prefs.setString(_testUserTypeKey, user.userType);
    await prefs.setString(_testUserEmailKey, user.email);
  }
  
  // Disable test mode
  static Future<void> disableTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isTestMode = false;
    _currentTestUser = null;
    
    // Clear from preferences
    await prefs.setBool(_testModeKey, false);
    await prefs.remove(_testUserIdKey);
    await prefs.remove(_testUserNameKey);
    await prefs.remove(_testUserTypeKey);
    await prefs.remove(_testUserEmailKey);
  }
  
  // Toggle test mode
  static Future<void> toggleTestMode() async {
    if (_isTestMode) {
      await disableTestMode();
    } else {
      // Will need to select a user first
      await disableTestMode(); // For now, just disable if toggled without user
    }
  }
}