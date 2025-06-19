import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'web_settings_screen.dart';

class WebSettingsLoginScreen extends StatefulWidget {
  final Function(bool success)? onLoginComplete;
  final bool isFullPage;
  
  const WebSettingsLoginScreen({
    Key? key,
    this.onLoginComplete,
    this.isFullPage = false,
  }) : super(key: key);

  @override
  State<WebSettingsLoginScreen> createState() => _WebSettingsLoginScreenState();
}

class _WebSettingsLoginScreenState extends State<WebSettingsLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _loginSuccess = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 WebSettingsLoginScreen: Screen initialized');
  }

  @override
  void dispose() {
    debugPrint('🔍 WebSettingsLoginScreen: Disposing screen');
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('🔍 WebSettingsLoginScreen: Login button pressed');
    debugPrint('🔍 Email: "${_emailController.text}"');
    debugPrint('🔍 Password length: ${_passwordController.text.length}');
    
    // Completely remove focus to prevent pointer event issues
    FocusScope.of(context).unfocus();
    // Dispose of focus nodes
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    
    // Add small delay to ensure focus is cleared
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      debugPrint('🔍 WebSettingsLoginScreen: Empty credentials detected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('🔍 WebSettingsLoginScreen: Setting loading state to true');
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 WebSettingsLoginScreen: Starting authentication process...');
      
      // Authenticate with Firebase Auth
      debugPrint('🔍 WebSettingsLoginScreen: Signing in with Firebase Auth...');
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      debugPrint('🔍 WebSettingsLoginScreen: Firebase sign in successful');
      
      // Check if user has super admin role
      debugPrint('🔍 WebSettingsLoginScreen: Checking super admin permissions...');
      final isSuperAdmin = await _authService.isSuperAdmin();
      
      if (!isSuperAdmin) {
        debugPrint('🔍 WebSettingsLoginScreen: User is not super admin');
        throw Exception('Super admin permissions required');
      }
      
      debugPrint('🔍 WebSettingsLoginScreen: Super admin verified successfully');
      
      // Show success state
      if (mounted) {
        setState(() {
          _loginSuccess = true;
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Redirecting...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Wait a moment for the success overlay to show
        await Future.delayed(const Duration(seconds: 2));
        
        // Try to return to previous screen
        if (mounted) {
          debugPrint('🔍 WebSettingsLoginScreen: Attempting to return to previous screen');
          
          // Method 1: Try using scheduleMicrotask
          Future.microtask(() {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          }).catchError((e) {
            debugPrint('🔍 WebSettingsLoginScreen: Microtask navigation failed: $e');
            
            // Method 2: Try using a timer as last resort
            Timer(const Duration(milliseconds: 100), () {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              }
            });
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 WebSettingsLoginScreen: Authentication failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        leading: widget.isFullPage 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false),
            )
          : null,
      ),
      body: Stack(
        children: [
          Center(
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Color(0xFF0F2D52),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Admin Login Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2D52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Super admin credentials required to access settings',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading && !_loginSuccess,
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      enabled: !_isLoading && !_loginSuccess,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _loginSuccess) ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2D52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Success overlay
          if (_loginSuccess)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Login successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading settings...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}