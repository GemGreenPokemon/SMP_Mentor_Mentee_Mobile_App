import 'package:flutter/material.dart';
import '../../utils/login_constants.dart';
import '../painters/geometric_pattern_painter.dart';
import 'feature_item.dart';

class BrandingPanel extends StatelessWidget {
  const BrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: LoginConstants.brandingGradientColors,
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
            padding: const EdgeInsets.all(LoginConstants.extraLargePadding),
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
                    height: LoginConstants.logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Student Mentorship\nProgram',
                  style: LoginConstants.brandingTitleStyle,
                ),
                
                const SizedBox(height: 20),
                
                // Subtitle
                Text(
                  'Empowering academic excellence through\nmentorship and collaboration',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Features
                Column(
                  children: LoginConstants.features
                      .map((feature) => FeatureItem(
                            icon: feature['icon'] as IconData,
                            text: feature['text'] as String,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}