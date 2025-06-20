import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../services/auth_service.dart';
import '../../../../utils/responsive.dart';
import 'utils/verification_constants.dart';
import 'utils/verification_helpers.dart';
import 'widgets/email_icon_container.dart';
import 'widgets/email_display_container.dart';
import 'widgets/resend_email_button.dart';
import 'widgets/verification_card.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;
  
  @override
  void initState() {
    super.initState();
    // Check email verification status periodically
    _timer = Timer.periodic(
      VerificationConstants.checkInterval, 
      (_) => _checkEmailVerified()
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    await _authService.reloadUser();
    
    if (_authService.isEmailVerified) {
      _timer?.cancel();
      
      if (mounted) {
        // Get user role and navigate to appropriate dashboard
        final userRole = await _authService.getUserRole();
        
        VerificationHelpers.showSuccessSnackBar(
          context,
          VerificationConstants.emailVerifiedMessage
        );
        
        // Navigate to appropriate dashboard based on role
        VerificationHelpers.navigateToDashboard(context, userRole);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _authService.sendEmailVerification();
      
      if (mounted) {
        VerificationHelpers.showSuccessSnackBar(
          context,
          VerificationConstants.verificationEmailSentMessage
        );
      }
    } catch (e) {
      if (mounted) {
        VerificationHelpers.showErrorSnackBar(
          context,
          VerificationHelpers.formatErrorMessage(e)
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, VerificationConstants.defaultRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      backgroundColor: VerificationConstants.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VerificationConstants.primaryColor.withOpacity(0.1),
              Colors.white,
              Colors.white,
              VerificationConstants.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop 
                    ? VerificationConstants.desktopMaxWidth 
                    : (isTablet 
                        ? VerificationConstants.tabletMaxWidth 
                        : double.infinity),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop || isTablet 
                    ? VerificationConstants.horizontalPadding 
                    : VerificationConstants.mobileHorizontalPadding,
                  vertical: 32
                ),
                child: VerificationCard(
                  children: [
                    // Email icon
                    const EmailIconContainer(),
                    const SizedBox(height: VerificationConstants.verticalSpacing),
                    
                    // Title
                    const Text(
                      VerificationConstants.title,
                      style: TextStyle(
                        fontSize: VerificationConstants.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: VerificationConstants.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VerificationConstants.smallVerticalSpacing),
                    
                    // Description
                    Text(
                      VerificationConstants.description,
                      style: TextStyle(
                        fontSize: VerificationConstants.bodyFontSize,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VerificationConstants.verticalSpacing),
                    
                    // User email display
                    if (_authService.currentUser?.email != null) ...[
                      EmailDisplayContainer(
                        email: _authService.currentUser!.email!,
                      ),
                      const SizedBox(height: VerificationConstants.verticalSpacing),
                    ],
                    
                    // Resend button
                    ResendEmailButton(
                      isResending: _isResending,
                      onPressed: _resendVerificationEmail,
                    ),
                    const SizedBox(height: VerificationConstants.smallVerticalSpacing),
                    
                    // Sign out button
                    TextButton(
                      onPressed: _signOut,
                      child: const Text(
                        VerificationConstants.signOutText,
                        style: TextStyle(
                          color: VerificationConstants.primaryColor,
                          fontSize: VerificationConstants.smallFontSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: VerificationConstants.verticalSpacing),
                    
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
      ),
    );
  }
}