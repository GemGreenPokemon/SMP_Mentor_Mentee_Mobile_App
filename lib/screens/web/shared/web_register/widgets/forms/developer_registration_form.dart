import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../utils/responsive.dart';
import '../../utils/registration_constants.dart';
import '../../utils/registration_validators.dart';
import '../../utils/registration_helpers.dart';
import '../shared/registration_button.dart';
import '../shared/password_field.dart';
import '../shared/form_field_wrapper.dart';
import '../decorative/info_panel.dart';

class DeveloperRegistrationForm extends StatefulWidget {
  final VoidCallback onBack;
  
  const DeveloperRegistrationForm({
    super.key,
    required this.onBack,
  });

  @override
  State<DeveloperRegistrationForm> createState() => _DeveloperRegistrationFormState();
}

class _DeveloperRegistrationFormState extends State<DeveloperRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null && mounted) {
        RegistrationHelpers.showSnackBar(
          context,
          'Developer account created successfully!',
          backgroundColor: RegistrationConstants.greenColor,
        );

        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Registration failed';
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak';
        } else if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }
        
        RegistrationHelpers.showSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        RegistrationHelpers.showSnackBar(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    
    return Row(
      children: [
        // Left side decorative panel - only visible on desktop/tablet
        if (isDesktop || isTablet) _buildDeveloperPanel(isDesktop),
        
        // Right side - Registration form
        Expanded(
          flex: isDesktop ? 5 : 12,
          child: Container(
            margin: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isDesktop 
                    ? RegistrationConstants.developerFormWidth 
                    : (isTablet 
                      ? RegistrationConstants.developerFormWidthTablet 
                      : double.infinity),
                  padding: const EdgeInsets.all(40),
                  decoration: RegistrationHelpers.getFormContainerDecoration(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          color: RegistrationConstants.primaryColor,
                        ),
                        const SizedBox(height: 20),
                        
                        // Title
                        const Text(
                          'Developer Registration',
                          style: TextStyle(
                            fontSize: RegistrationConstants.titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: RegistrationConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a developer account for testing',
                          style: TextStyle(
                            fontSize: RegistrationConstants.subtitleFontSize,
                            color: RegistrationConstants.greyColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Email field
                        FormFieldWrapper(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: RegistrationValidators.validateEmail,
                        ),
                        const SizedBox(height: 20),
                        
                        // Password field
                        PasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          validator: RegistrationValidators.validatePassword,
                        ),
                        const SizedBox(height: 32),
                        
                        // Register button
                        RegistrationButton(
                          text: 'CREATE DEVELOPER ACCOUNT',
                          onPressed: _handleRegistration,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 20),
                        
                        // Development notice
                        const InfoPanel(
                          message: RegistrationConstants.developerInfoMessage,
                          type: InfoPanelType.info,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperPanel(bool isDesktop) {
    return Expanded(
      flex: isDesktop ? 4 : 3,
      child: Container(
        height: MediaQuery.of(context).size.height - 48,
        decoration: RegistrationHelpers.getPanelDecoration(),
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.code,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Developer Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick registration for development and testing purposes. No database validation required.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RegistrationConstants.orangeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: RegistrationConstants.orangeColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: RegistrationConstants.orangeColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        RegistrationConstants.developerWarningMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}