import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class TestModeManager extends ChangeNotifier {
  static const String _testModeKey = 'test_mode_enabled';
  
  // Mentor keys
  static const String _testMentorIdKey = 'test_mentor_id';
  static const String _testMentorNameKey = 'test_mentor_name';
  static const String _testMentorEmailKey = 'test_mentor_email';
  
  // Mentee keys
  static const String _testMenteeIdKey = 'test_mentee_id';
  static const String _testMenteeNameKey = 'test_mentee_name';
  static const String _testMenteeEmailKey = 'test_mentee_email';
  
  // Legacy keys for backward compatibility
  static const String _testUserIdKey = 'test_user_id';
  static const String _testUserNameKey = 'test_user_name';
  static const String _testUserTypeKey = 'test_user_type';
  static const String _testUserEmailKey = 'test_user_email';
  
  // Singleton instance
  static final TestModeManager _instance = TestModeManager._internal();
  factory TestModeManager() => _instance;
  TestModeManager._internal();
  
  // Static getters for backward compatibility
  static TestModeManager get instance => _instance;
  static bool get isTestMode => _instance._isTestMode;
  static User? get currentTestUser => _instance._currentTestMentor; // For backward compatibility
  static User? get currentTestMentor => _instance._currentTestMentor;
  static User? get currentTestMentee => _instance._currentTestMentee;
  static bool get hasCompleteTestData => _instance._isTestMode && _instance._currentTestMentor != null && _instance._currentTestMentee != null;
  
  // Instance variables
  bool _isTestMode = false;
  User? _currentTestMentor;
  User? _currentTestMentee;
  
  // Instance getters
  bool get isTestModeInstance => _isTestMode;
  User? get currentTestMentorInstance => _currentTestMentor;
  User? get currentTestMenteeInstance => _currentTestMentee;
  
  // Initialize test mode from SharedPreferences
  static Future<void> initialize() async {
    await _instance._initialize();
  }
  
  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isTestMode = prefs.getBool(_testModeKey) ?? false;
    
    if (_isTestMode) {
      // Try to load new format first
      final mentorId = prefs.getString(_testMentorIdKey);
      final menteeId = prefs.getString(_testMenteeIdKey);
      
      if (mentorId != null) {
        // Load mentor
        _currentTestMentor = User(
          id: mentorId,
          name: prefs.getString(_testMentorNameKey) ?? 'Test Mentor',
          email: prefs.getString(_testMentorEmailKey) ?? 'mentor@test.com',
          userType: 'mentor',
          createdAt: DateTime.now(),
        );
      }
      
      if (menteeId != null) {
        // Load mentee
        _currentTestMentee = User(
          id: menteeId,
          name: prefs.getString(_testMenteeNameKey) ?? 'Test Mentee',
          email: prefs.getString(_testMenteeEmailKey) ?? 'mentee@test.com',
          userType: 'mentee',
          createdAt: DateTime.now(),
        );
      }
      
      // Fallback to legacy format if new format not found
      if (_currentTestMentor == null) {
        final userId = prefs.getString(_testUserIdKey);
        if (userId != null) {
          _currentTestMentor = User(
            id: userId,
            name: prefs.getString(_testUserNameKey) ?? 'Test User',
            email: prefs.getString(_testUserEmailKey) ?? 'test@example.com',
            userType: prefs.getString(_testUserTypeKey) ?? 'mentor',
            createdAt: DateTime.now(),
          );
        }
      }
    }
    notifyListeners();
  }
  
  // Enable test mode with both mentor and mentee
  static Future<void> enableTestMode({required User mentor, User? mentee}) async {
    await _instance._enableTestMode(mentor: mentor, mentee: mentee);
  }
  
  Future<void> _enableTestMode({required User mentor, User? mentee}) async {
    final prefs = await SharedPreferences.getInstance();
    
    _isTestMode = true;
    _currentTestMentor = mentor;
    _currentTestMentee = mentee;
    
    // Save to preferences
    await prefs.setBool(_testModeKey, true);
    
    // Save mentor
    await prefs.setString(_testMentorIdKey, mentor.id);
    await prefs.setString(_testMentorNameKey, mentor.name);
    await prefs.setString(_testMentorEmailKey, mentor.email);
    
    // Save mentee if provided
    if (mentee != null) {
      await prefs.setString(_testMenteeIdKey, mentee.id);
      await prefs.setString(_testMenteeNameKey, mentee.name);
      await prefs.setString(_testMenteeEmailKey, mentee.email);
    } else {
      // Clear mentee data if none provided
      await prefs.remove(_testMenteeIdKey);
      await prefs.remove(_testMenteeNameKey);
      await prefs.remove(_testMenteeEmailKey);
    }
    
    // Also save in legacy format for backward compatibility
    await prefs.setString(_testUserIdKey, mentor.id);
    await prefs.setString(_testUserNameKey, mentor.name);
    await prefs.setString(_testUserTypeKey, mentor.userType);
    await prefs.setString(_testUserEmailKey, mentor.email);
    
    notifyListeners();
  }
  
  // Disable test mode
  static Future<void> disableTestMode() async {
    await _instance._disableTestMode();
  }
  
  Future<void> _disableTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isTestMode = false;
    _currentTestMentor = null;
    _currentTestMentee = null;
    
    // Clear from preferences
    await prefs.setBool(_testModeKey, false);
    
    // Clear mentor data
    await prefs.remove(_testMentorIdKey);
    await prefs.remove(_testMentorNameKey);
    await prefs.remove(_testMentorEmailKey);
    
    // Clear mentee data
    await prefs.remove(_testMenteeIdKey);
    await prefs.remove(_testMenteeNameKey);
    await prefs.remove(_testMenteeEmailKey);
    
    // Clear legacy data
    await prefs.remove(_testUserIdKey);
    await prefs.remove(_testUserNameKey);
    await prefs.remove(_testUserTypeKey);
    await prefs.remove(_testUserEmailKey);
    
    notifyListeners();
  }
  
  // Toggle test mode
  static Future<void> toggleTestMode() async {
    await _instance._toggleTestMode();
  }
  
  Future<void> _toggleTestMode() async {
    if (_isTestMode) {
      await _disableTestMode();
    } else {
      // Will need to select a user first
      await _disableTestMode(); // For now, just disable if toggled without user
    }
  }
  
  // Get the appropriate test user based on user type
  static User? getTestUserForType(String userType) {
    return _instance._getTestUserForType(userType);
  }
  
  User? _getTestUserForType(String userType) {
    if (!_isTestMode) return null;
    
    if (userType == 'mentor') {
      return _currentTestMentor;
    } else if (userType == 'mentee') {
      return _currentTestMentee;
    }
    
    return null;
  }
}