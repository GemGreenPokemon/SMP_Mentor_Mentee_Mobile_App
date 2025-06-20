import 'package:flutter/material.dart';
import '../../utils/login_constants.dart';

class LoginPanel extends StatelessWidget {
  final Widget child;

  const LoginPanel({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(LoginConstants.extraLargePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back',
            style: LoginConstants.titleStyle,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Sign in to access your dashboard',
            style: LoginConstants.subtitleStyle.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          child,
        ],
      ),
    );
  }
}