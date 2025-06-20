class LoginFormData {
  final String email;
  final String password;

  const LoginFormData({
    required this.email,
    required this.password,
  });

  bool get isValid => email.isNotEmpty && password.isNotEmpty;

  LoginFormData copyWith({
    String? email,
    String? password,
  }) {
    return LoginFormData(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}