import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import 'utils/registration_constants.dart';
import 'widgets/painters/background_pattern_painter.dart';
import 'widgets/panels/registration_branding_panel.dart';
import 'widgets/panels/registration_form_panel.dart';
import 'widgets/forms/unified_registration_form.dart';
import 'widgets/registration_card.dart';

class WebRegisterScreen extends StatefulWidget {
  const WebRegisterScreen({super.key});

  @override
  State<WebRegisterScreen> createState() => _WebRegisterScreenState();
}

class _WebRegisterScreenState extends State<WebRegisterScreen> {
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
            colors: RegistrationConstants.backgroundGradientColors,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
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
          maxWidth: RegistrationConstants.maxDesktopWidth,
          maxHeight: RegistrationConstants.maxDesktopHeight,
        ),
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RegistrationConstants.largeBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RegistrationConstants.largeBorderRadius),
          child: Row(
            children: [
              // Left branding panel
              const Expanded(
                flex: 3,
                child: RegistrationBrandingPanel(),
              ),
              // Right registration panel
              Expanded(
                flex: 2,
                child: RegistrationFormPanel(
                  child: const UnifiedRegistrationForm(),
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
        padding: const EdgeInsets.all(RegistrationConstants.largePadding),
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
                height: RegistrationConstants.mobileLogoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 60),
            // Registration form in card
            RegistrationCard(
              child: const UnifiedRegistrationForm(),
            ),
          ],
        ),
      ),
    );
  }
}