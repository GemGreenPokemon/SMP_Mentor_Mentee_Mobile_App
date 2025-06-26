import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/acknowledgment_controller.dart';
import 'utils/acknowledgment_constants.dart';
import 'widgets/panels/branding_panel.dart';
import 'widgets/forms/acknowledgment_form.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';

class WebMenteeAcknowledgmentScreen extends StatefulWidget {
  const WebMenteeAcknowledgmentScreen({super.key});

  @override
  State<WebMenteeAcknowledgmentScreen> createState() => _WebMenteeAcknowledgmentScreenState();
}

class _WebMenteeAcknowledgmentScreenState extends State<WebMenteeAcknowledgmentScreen> {
  late final AcknowledgmentController _controller;

  @override
  void initState() {
    super.initState();
    print('🎯🎯🎯 WebMenteeAcknowledgmentScreen initState called!');
    print('🎯🎯🎯 This means the acknowledgment screen is being created');
    _controller = AcknowledgmentController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _controller.submitAcknowledgment(context);
    
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Acknowledgment submitted successfully!'),
          backgroundColor: AcknowledgmentColors.successGreen,
        ),
      );
      
      // Navigate to mentee dashboard
      Navigator.pushReplacementNamed(context, '/mentee');
    } else if (_controller.errorMessage != null && mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AcknowledgmentColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎯🎯🎯 WebMenteeAcknowledgmentScreen build called!');
    print('🎯🎯🎯 Screen is being rendered');
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final showSidePanel = isDesktop || isTablet;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ChangeNotifierProvider.value(
        value: _controller,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AcknowledgmentColors.primaryDark.withOpacity(0.1),
                Colors.white,
                Colors.white,
                AcknowledgmentColors.primaryDark.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Left side branding panel - only visible on desktop/tablet
                if (showSidePanel)
                  Expanded(
                    flex: isDesktop ? 4 : 3,
                    child: const BrandingPanel(),
                  ),
                
                // Right side acknowledgment form
                Expanded(
                  flex: isDesktop ? 3 : (isTablet ? 4 : 1),
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: showSidePanel ? double.infinity : 500,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: showSidePanel 
                            ? AcknowledgmentSizes.spacingXXLarge 
                            : AcknowledgmentSizes.spacingLarge,
                        vertical: AcknowledgmentSizes.spacingXLarge,
                      ),
                      child: Consumer<AcknowledgmentController>(
                        builder: (context, controller, _) {
                          return AcknowledgmentForm(
                            controller: controller,
                            onSubmit: _handleSubmit,
                            showLogo: !showSidePanel,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}