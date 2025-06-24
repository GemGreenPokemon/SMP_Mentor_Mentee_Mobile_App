import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../services/auth_service.dart';

class RegistrationService {
  final AuthService _authService = AuthService();

  /// Register a new user with the provided details
  /// The user's role will be determined from the database based on their whitelist entry
  Future<UserCredential?> registerUser({
    required String name,
    required String email,
    required String password,
    String? studentId,
  }) async {
    try {
      // The auth service handles:
      // 1. Name whitelist validation
      // 2. Firebase auth account creation
      // 3. Email verification sending
      // 4. Database update with auth UID
      // 5. Custom claims setup based on database userType
      
      final credential = await _authService.registerWithNameValidation(
        name: name,
        email: email,
        password: password,
      );
      
      // If we need to store additional data (like student ID), 
      // we could do it here in the future
      
      return credential;
    } catch (e) {
      // Re-throw the exception to be handled by the UI
      throw e;
    }
  }

  /// Get user-friendly error message for registration errors
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'name-not-approved':
          return 'Your name is not on the approved list. Please contact your coordinator.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Registration failed: ${error.message ?? error.code}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Validate registration data before submission
  Map<String, String?> validateRegistrationData({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? studentId,
  }) {
    final errors = <String, String?>{};
    
    // Name validation
    if (name.isEmpty) {
      errors['name'] = 'Please enter your name';
    }
    
    // Email validation
    if (email.isEmpty) {
      errors['email'] = 'Please enter your email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email';
    }
    
    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Please enter a password';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    
    // Confirm password validation
    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Please confirm your password';
    } else if (confirmPassword != password) {
      errors['confirmPassword'] = 'Passwords do not match';
    }
    
    // Student ID validation (optional field)
    if (studentId != null && studentId.isNotEmpty) {
      if (!RegExp(r'^\d{8}$').hasMatch(studentId)) {
        errors['studentId'] = 'Student ID should be 8 digits';
      }
    }
    
    return errors;
  }
}