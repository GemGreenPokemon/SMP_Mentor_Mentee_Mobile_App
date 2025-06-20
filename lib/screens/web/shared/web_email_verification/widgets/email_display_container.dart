import 'package:flutter/material.dart';
import '../utils/verification_constants.dart';

class EmailDisplayContainer extends StatelessWidget {
  final String email;
  
  const EmailDisplayContainer({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(VerificationConstants.containerBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            email,
            style: const TextStyle(
              fontSize: VerificationConstants.smallFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}