import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                const Icon(
                  Icons.people_outline,
                  size: 100,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(height: 24),
                // App Title
                const Text(
                  'SMP Mentor-Mentee',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                // Role Selection Buttons
                _buildRoleButton(
                  context,
                  'Login as Mentee',
                  Icons.school,
                  () {
                    debugPrint('Mentee button pressed');
                    Navigator.pushReplacementNamed(context, '/mentee');
                  },
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  'Login as Mentor',
                  Icons.psychology,
                  () {
                    debugPrint('Mentor button pressed');
                    Navigator.pushReplacementNamed(context, '/mentor');
                  },
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  'Login as Coordinator',
                  Icons.admin_panel_settings,
                  () {
                    debugPrint('Coordinator button pressed');
                    Navigator.pushReplacementNamed(context, '/coordinator');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 