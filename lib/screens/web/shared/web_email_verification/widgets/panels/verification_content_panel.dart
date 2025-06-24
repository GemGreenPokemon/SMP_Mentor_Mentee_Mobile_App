import 'package:flutter/material.dart';
import '../../utils/verification_constants.dart';

class VerificationContentPanel extends StatelessWidget {
  final bool isResending;
  final String email;
  final VoidCallback onResend;
  final VoidCallback onSignOut;

  const VerificationContentPanel({
    super.key,
    required this.isResending,
    required this.email,
    required this.onResend,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(VerificationConstants.extraLargePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email icon
                  Container(
                    width: VerificationConstants.iconContainerSize,
                    height: VerificationConstants.iconContainerSize,
                    decoration: BoxDecoration(
                      color: VerificationConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(VerificationConstants.iconContainerRadius),
                    ),
                    child: const Icon(
                      VerificationConstants.emailIcon,
                      size: VerificationConstants.iconSize,
                      color: VerificationConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: VerificationConstants.verticalSpacing),
                  
                  // Title
                  const Text(
                    VerificationConstants.title,
                    style: VerificationConstants.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VerificationConstants.smallVerticalSpacing),
                  
                  // Description
                  Text(
                    VerificationConstants.description,
                    style: VerificationConstants.subtitleStyle.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VerificationConstants.verticalSpacing),
                  
                  // User email display
                  if (email.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(VerificationConstants.containerBorderRadius),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: VerificationConstants.smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                  
                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: VerificationConstants.buttonHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: VerificationConstants.buttonGradientColors,
                        ),
                        borderRadius: BorderRadius.circular(VerificationConstants.buttonBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: VerificationConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isResending ? null : onResend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(VerificationConstants.buttonBorderRadius),
                          ),
                        ),
                        child: isResending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'RESEND VERIFICATION EMAIL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign out button
                  TextButton(
                    onPressed: onSignOut,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      VerificationConstants.signOutText,
                      style: TextStyle(
                        color: VerificationConstants.primaryColor,
                        fontSize: VerificationConstants.smallFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Help text
                  Text(
                    VerificationConstants.helpText,
                    style: TextStyle(
                      fontSize: VerificationConstants.tinyFontSize,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}