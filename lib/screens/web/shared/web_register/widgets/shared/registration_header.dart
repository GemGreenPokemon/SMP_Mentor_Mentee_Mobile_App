import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';

class RegistrationHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final String backButtonText;
  
  const RegistrationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.backButtonText = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back, 
            color: RegistrationConstants.primaryColor,
          ),
          label: Text(
            backButtonText,
            style: const TextStyle(
              color: RegistrationConstants.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: RegistrationConstants.titleFontSize,
            fontWeight: FontWeight.bold,
            color: RegistrationConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: RegistrationConstants.subtitleFontSize,
            color: RegistrationConstants.greyColor,
          ),
        ),
      ],
    );
  }
}