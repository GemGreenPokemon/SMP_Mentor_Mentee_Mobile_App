import 'login_constants.dart';

class LoginValidators {
  static final RegExp _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return LoginConstants.emailRequired;
    }
    if (!_emailRegExp.hasMatch(value)) {
      return LoginConstants.emailInvalid;
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LoginConstants.passwordRequired;
    }
    if (value.length < 6) {
      return LoginConstants.passwordTooShort;
    }
    return null;
  }
  
  static String getFirebaseErrorMessage(String errorCode, String? defaultMessage) {
    return LoginConstants.errorMessages[errorCode] ?? 
           'Login failed: ${defaultMessage ?? errorCode}';
  }
}