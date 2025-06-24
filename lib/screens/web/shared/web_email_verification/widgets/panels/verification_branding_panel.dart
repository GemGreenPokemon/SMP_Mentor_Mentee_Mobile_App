import 'package:flutter/material.dart';
import '../../utils/verification_constants.dart';
import '../painters/geometric_pattern_painter.dart';

class VerificationBrandingPanel extends StatelessWidget {
  const VerificationBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: VerificationConstants.brandingGradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Subtle geometric pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(VerificationConstants.extraLargePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo with glow effect
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/My_SMP_Logo.png',
                    height: VerificationConstants.logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Almost There!',
                  style: VerificationConstants.brandingTitleStyle,
                ),
                
                const SizedBox(height: 20),
                
                // Subtitle
                Text(
                  'Your account is created. We just need to\nverify your email address.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Steps
                _buildStep(
                  icon: Icons.mail_outline,
                  title: 'Check Your Email',
                  description: 'We sent a verification link',
                ),
                _buildStep(
                  icon: Icons.link,
                  title: 'Click the Link',
                  description: 'Verify your email address',
                ),
                _buildStep(
                  icon: Icons.check_circle_outline,
                  title: 'Get Started',
                  description: 'Access your dashboard',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}