import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../services/auth_service.dart';
import '../../../../utils/responsive.dart';
import 'utils/verification_constants.dart';
import 'utils/verification_helpers.dart';
import 'widgets/painters/verification_pattern_painter.dart';
import 'widgets/panels/verification_branding_panel.dart';
import 'widgets/panels/verification_content_panel.dart';
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
        VerificationHelpers.showSuccessSnackBar(
          context,
          VerificationConstants.emailVerifiedMessage
        );
        
        // Navigate back to AuthWrapper to let it decide what to show
        // Don't navigate directly to role-based routes
        Navigator.pushReplacementNamed(context, '/');
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
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final isMobile = !isDesktop && !isTablet;
    
    return Scaffold(
      body: Container(
        height: screenSize.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: VerificationConstants.backgroundGradientColors,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: VerificationPatternPainter(),
              ),
            ),
            
            // Main content
            if (isMobile) _buildMobileLayout() else _buildDesktopLayout(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: VerificationConstants.maxDesktopWidth,
          maxHeight: VerificationConstants.maxDesktopHeight,
        ),
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VerificationConstants.largeBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VerificationConstants.largeBorderRadius),
          child: Row(
            children: [
              // Left branding panel
              const Expanded(
                flex: 3,
                child: VerificationBrandingPanel(),
              ),
              // Right content panel
              Expanded(
                flex: 2,
                child: VerificationContentPanel(
                  isResending: _isResending,
                  email: _authService.currentUser?.email ?? '',
                  onResend: _resendVerificationEmail,
                  onSignOut: _signOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VerificationConstants.largePadding),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Mobile logo
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
                height: VerificationConstants.mobileLogoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 60),
            // Verification content in card
            VerificationCard(
              child: Column(
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
                        _authService.currentUser!.email!,
                        style: TextStyle(
                          fontSize: VerificationConstants.smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: VerificationConstants.verticalSpacing),
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
                        onPressed: _isResending ? null : _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(VerificationConstants.buttonBorderRadius),
                          ),
                        ),
                        child: _isResending
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
          ],
        ),
      ),
    );
  }
}