class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  factory ValidationResult.success() {
    return ValidationResult(isValid: true);
  }

  factory ValidationResult.error(String message, ValidationErrorType type) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

enum ValidationErrorType {
  nameNotApproved,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  invalidStudentId,
  requiredField,
  passwordMismatch,
  other,
}