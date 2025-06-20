import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utils/responsive.dart';
import '../../../../services/auth_service.dart';
import '../web_register/web_register_screen.dart';
import '../web_email_verification/web_email_verification_screen.dart';
import 'models/login_state.dart';
import 'utils/login_constants.dart';
import 'utils/login_validators.dart';
import 'widgets/painters/background_pattern_painter.dart';
import 'widgets/panels/branding_panel.dart';
import 'widgets/panels/login_panel.dart';
import 'widgets/panels/mobile_logo.dart';
import 'widgets/login_form.dart';
import 'widgets/login_card.dart';
import 'widgets/dialogs/forgot_password_dialog.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  LoginState _state = const LoginState();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateState(LoginState Function(LoginState) update) {
    setState(() {
      _state = update(_state);
    });
  }

  void _togglePasswordVisibility() {
    _updateState((state) => state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    _updateState((state) => state.copyWith(isLoggingIn: true));
    
    try {
      // Sign in with Firebase Auth
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Check if email is verified (bypass for dev account)
      final isDevAccount = _emailController.text.trim() == 'sunsetcoding.dev@gmail.com';
      if (!_authService.isEmailVerified && !isDevAccount) {
        // Navigate to email verification screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EmailVerificationScreen(),
            ),
          );
        }
        return;
      }
      
      // Show database initialization status for regular users
      if (_emailController.text.trim() != 'sunsetcoding.dev@gmail.com') {
        _updateState((state) => state.copyWith(isInitializingDatabase: true));
      }
      
      // Show success message
      if (mounted) {
        _updateState((state) => state.copyWith(isInitializingDatabase: false));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // AuthWrapper will handle navigation based on auth state change
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = LoginValidators.getFirebaseErrorMessage(
          e.code, 
          e.message,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        _updateState((state) => state.copyWith(isLoggingIn: false));
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordDialog(
        onSendResetEmail: _authService.sendPasswordResetEmail,
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebRegisterScreen(),
      ),
    );
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
            colors: LoginConstants.backgroundGradientColors,
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
          maxWidth: LoginConstants.maxDesktopWidth,
          maxHeight: LoginConstants.maxDesktopHeight,
        ),
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LoginConstants.largeBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LoginConstants.largeBorderRadius),
          child: Row(
            children: [
              // Left branding panel
              const Expanded(
                flex: 3,
                child: BrandingPanel(),
              ),
              // Right login panel
              Expanded(
                flex: 2,
                child: LoginPanel(
                  child: _buildLoginForm(),
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
        padding: const EdgeInsets.all(LoginConstants.largePadding),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const MobileLogo(),
            const SizedBox(height: 60),
            LoginCard(
              child: _buildLoginForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return LoginForm(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      isPasswordVisible: _state.isPasswordVisible,
      isLoggingIn: _state.isLoggingIn,
      isInitializingDatabase: _state.isInitializingDatabase,
      onTogglePasswordVisibility: _togglePasswordVisibility,
      onLogin: _login,
      onForgotPassword: _showForgotPasswordDialog,
      onNavigateToRegister: _navigateToRegister,
    );
  }
}