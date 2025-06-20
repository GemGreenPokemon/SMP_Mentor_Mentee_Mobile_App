import '../models/validation_result.dart';
import 'registration_constants.dart';

class RegistrationValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validateCoordinatorEmail(String? value) {
    final basicValidation = validateEmail(value);
    if (basicValidation != null) {
      return basicValidation;
    }
    if (value != null && !value.endsWith('ucmerced.edu')) {
      return 'Must use a UC Merced email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < RegistrationConstants.passwordMinLength) {
      return 'Password must be at least ${RegistrationConstants.passwordMinLength} characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateStudentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your student ID';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Student ID should be ${RegistrationConstants.studentIdLength} digits';
    }
    return null;
  }

  static String? validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your department';
    }
    return null;
  }

  static String? validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your position';
    }
    return null;
  }

  static String getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'name-not-approved':
        return RegistrationConstants.nameNotApprovedMessage;
      case 'email-already-in-use':
        return RegistrationConstants.emailAlreadyInUseMessage;
      case 'weak-password':
        return RegistrationConstants.weakPasswordMessage;
      case 'invalid-email':
        return RegistrationConstants.invalidEmailMessage;
      default:
        return 'Registration failed: $errorCode';
    }
  }
}