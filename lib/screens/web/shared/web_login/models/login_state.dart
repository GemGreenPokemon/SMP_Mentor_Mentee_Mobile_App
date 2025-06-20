class LoginState {
  final bool isLoggingIn;
  final bool isInitializingDatabase;
  final bool isPasswordVisible;
  final String? errorMessage;

  const LoginState({
    this.isLoggingIn = false,
    this.isInitializingDatabase = false,
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoggingIn,
    bool? isInitializingDatabase,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return LoginState(
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      isInitializingDatabase: isInitializingDatabase ?? this.isInitializingDatabase,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  bool get isProcessing => isLoggingIn || isInitializingDatabase;
}