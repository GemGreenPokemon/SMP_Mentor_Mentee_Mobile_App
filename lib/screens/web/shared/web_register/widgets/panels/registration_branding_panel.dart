import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';
import '../painters/registration_pattern_painter.dart';
import 'feature_item.dart';

class RegistrationBrandingPanel extends StatelessWidget {
  const RegistrationBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: RegistrationConstants.brandingGradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Subtle geometric pattern
          Positioned.fill(
            child: CustomPaint(
              painter: RegistrationPatternPainter(),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(RegistrationConstants.extraLargePadding),
            child: Center(
              child: SingleChildScrollView(
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
                        height: RegistrationConstants.logoHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Title
                    const Text(
                      'Join Our\nMentorship Program',
                      style: RegistrationConstants.brandingTitleStyle,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Text(
                      'Start your journey towards academic excellence\nwith personalized guidance and support',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Features
                    Column(
                      children: RegistrationConstants.features
                          .map((feature) => FeatureItem(
                                icon: feature['icon'] as IconData,
                                text: feature['text'] as String,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}