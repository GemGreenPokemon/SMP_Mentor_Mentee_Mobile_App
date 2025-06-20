import 'package:flutter/material.dart';
import '../utils/login_constants.dart';
import '../utils/login_validators.dart';
import 'fields/premium_text_field.dart';
import 'fields/premium_button.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoggingIn;
  final bool isInitializingDatabase;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onNavigateToRegister;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoggingIn,
    required this.isInitializingDatabase,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onNavigateToRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          PremiumTextField(
            controller: emailController,
            label: 'Email Address',
            icon: LoginConstants.emailIcon,
            isPassword: false,
            validator: LoginValidators.validateEmail,
          ),
          
          const SizedBox(height: 24),
          
          // Password field
          PremiumTextField(
            controller: passwordController,
            label: 'Password',
            icon: LoginConstants.passwordIcon,
            isPassword: true,
            isPasswordVisible: isPasswordVisible,
            onTogglePasswordVisibility: onTogglePasswordVisibility,
            validator: LoginValidators.validatePassword,
          ),
          
          const SizedBox(height: 16),
          
          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: LoginConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Sign in button
          PremiumButton(
            onPressed: onLogin,
            isLoading: isLoggingIn || isInitializingDatabase,
          ),
          
          // Status message
          if (isInitializingDatabase) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      LoginConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Connecting to database...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Register link
          Center(
            child: TextButton(
              onPressed: onNavigateToRegister,
              style: TextButton.styleFrom(
                foregroundColor: LoginConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                "Don't have an account? Register",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}