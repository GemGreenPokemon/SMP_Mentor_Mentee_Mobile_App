import 'package:flutter/material.dart';
import '../utils/verification_constants.dart';

class ResendEmailButton extends StatelessWidget {
  final bool isResending;
  final VoidCallback onPressed;
  
  const ResendEmailButton({
    super.key,
    required this.isResending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: VerificationConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: isResending ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VerificationConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VerificationConstants.buttonBorderRadius),
          ),
        ),
        child: isResending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                VerificationConstants.resendButtonText,
                style: TextStyle(
                  fontSize: VerificationConstants.bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}