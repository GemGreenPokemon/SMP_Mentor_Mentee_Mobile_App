import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';
import '../../utils/registration_helpers.dart';

class RoleBenefitsPanel extends StatelessWidget {
  final bool isDesktop;
  
  const RoleBenefitsPanel({
    super.key,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: isDesktop ? 4 : 3,
      child: Container(
        height: MediaQuery.of(context).size.height - 48,
        decoration: RegistrationHelpers.getPanelDecoration(),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/My_SMP_Logo.png',
              height: RegistrationConstants.logoHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const Text(
              'Join the Student Mentorship Program',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create your account to start your mentorship journey. Whether you\'re seeking guidance or providing it, our platform connects you with the UC Merced community.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            _buildBenefitsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      'Connect with mentors and mentees',
      'Access exclusive resources',
      'Track your progress and growth',
      'Join a supportive community',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '✓ $benefit',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        )).toList(),
      ),
    );
  }
}