import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // App Logo
                SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/My_SMP_Logo.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Subtitle
                      const Text(
                        'Login as a...',
                        style: TextStyle(
                          fontSize: 22,
                          color: Color(0xFF6B7280), // Slightly darker grey for better readability
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Role Selection Buttons
                      _buildRoleButton(
                        context,
                        'Mentee',
                        Icons.school,
                        () {
                          debugPrint('Mentee button pressed');
                          Navigator.pushReplacementNamed(context, '/mentee');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        context,
                        'Mentor',
                        Icons.psychology,
                        () {
                          debugPrint('Mentor button pressed');
                          Navigator.pushReplacementNamed(context, '/mentor');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        context,
                        'Coordinator',
                        Icons.admin_panel_settings,
                        () {
                          debugPrint('Coordinator button pressed');
                          Navigator.pushReplacementNamed(context, '/coordinator');
                        },
                      ),
                    ],
                  ),
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
      height: 52, // Slightly shorter for better proportion
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20), // Smaller icon size
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005487), // Deep Sky Blue
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Less rounded corners
          ),
          elevation: 0, // Flat design
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3, // Slight letter spacing for better readability
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
} 