import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/real_time_user_service.dart';
import '../screens/web_login_screen.dart';
import '../screens/login_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/web_mentee_dashboard_screen.dart';
import '../screens/mentee_dashboard_screen.dart';
import '../screens/web_mentor_dashboard_screen.dart';
import '../screens/mentor_dashboard_screen.dart';
import '../screens/web_coordinator_dashboard_screen.dart';
import '../screens/coordinator_dashboard_screen.dart';
import '../screens/developer_home_screen.dart';
import '../utils/responsive.dart';
import '../utils/developer_session.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  bool _isLoading = true;
  String? _userRole;
  bool _isInitializingDatabase = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    
    // Check current auth state
    await _checkCurrentUser();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (mounted) {
      if (user == null) {
        // User signed out
        setState(() {
          _isLoading = false;
          _userRole = null;
        });
      } else {
        // User signed in, get their role
        await _checkCurrentUser();
      }
    }
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = _authService.currentUser;
      
      if (user == null) {
        // No user signed in
        setState(() {
          _isLoading = false;
          _userRole = null;
        });
        return;
      }

      // Special handling for dev account - bypass all database checks
      final isDevAccount = user.email == 'sunsetcoding.dev@gmail.com';
      print('🔧 Checking user: ${user.email}, isDevAccount: $isDevAccount');
      
      String? role;
      if (isDevAccount) {
        // Dev account gets hardcoded developer role - no database lookup needed
        role = 'developer';
        print('🔧 Dev account detected - granting immediate developer access with role: $role');
      } else {
        // Regular users: Initialize database and get role
        setState(() {
          _isInitializingDatabase = true;
        });
        
        // Start database connection
        final universityPath = _authService.universityPath;
        _realTimeUserService.startListening(universityPath);
        
        // Get role from database with retry logic (this will wait for connection)
        role = await _authService.getUserRole();
        print('🔧 Regular user role from database: $role');
        
        setState(() {
          _isInitializingDatabase = false;
        });
      }
      
      // Handle developer session
      if (role?.toLowerCase() == 'developer' || role?.toLowerCase() == 'super_admin' || isDevAccount) {
        await DeveloperSession.enable();
      } else {
        await DeveloperSession.disable();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userRole = role;
        });
      }
    } catch (e) {
      print('Error checking current user: $e');
      
      // Even if there's an error, check if this is the dev account
      final user = _authService.currentUser;
      final isDevAccount = user?.email == 'sunsetcoding.dev@gmail.com';
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // For dev account, ensure developer role even if there's an error
          _userRole = isDevAccount ? 'developer' : null;
        });
      }
      
      if (isDevAccount) {
        print('🔧 Error occurred but dev account detected - forcing developer role');
        try {
          await DeveloperSession.enable();
        } catch (sessionError) {
          print('🔧 Error enabling developer session: $sessionError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _LoadingScreen(
        isInitializingDatabase: _isInitializingDatabase,
      );
    }

    final user = _authService.currentUser;

    // No user signed in - show login screen
    if (user == null) {
      return Responsive.isWeb() ? const WebLoginScreen() : const LoginScreen();
    }

    // User signed in but email not verified - show email verification screen
    // Exception: bypass email verification for dev account
    final isDevAccount = user.email == 'sunsetcoding.dev@gmail.com';
    if (!_authService.isEmailVerified && !isDevAccount) {
      return const EmailVerificationScreen();
    }

    // User signed in and email verified - navigate based on role
    return _buildDashboardForRole(_userRole);
  }

  Widget _buildDashboardForRole(String? role) {
    // Special handling for dev account - always grant developer access
    final user = _authService.currentUser;
    final isDevAccount = user?.email == 'sunsetcoding.dev@gmail.com';
    
    if (isDevAccount) {
      return const DeveloperHomeScreen();
    }
    
    switch (role?.toLowerCase()) {
      case 'mentee':
        return Responsive.isWeb() 
            ? const WebMenteeDashboardScreen() 
            : const MenteeDashboardScreen();
      case 'mentor':
        return Responsive.isWeb() 
            ? const WebMentorDashboardScreen() 
            : const MentorDashboardScreen();
      case 'coordinator':
        return Responsive.isWeb() 
            ? const WebCoordinatorDashboardScreen() 
            : const CoordinatorDashboardScreen();
      case 'developer':
      case 'super_admin':
        return const DeveloperHomeScreen();
      default:
        // Unknown role - sign out and show error
        return _UnknownRoleScreen(onSignOut: () async {
          await _authService.signOut();
        });
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  final bool isInitializingDatabase;
  
  const _LoadingScreen({this.isInitializingDatabase = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2D52).withOpacity(0.1),
              Colors.white,
              Colors.white,
              const Color(0xFF0F2D52).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF0F2D52),
              ),
              const SizedBox(height: 24),
              Text(
                isInitializingDatabase ? 'Connecting to database...' : 'Loading...',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF0F2D52),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isInitializingDatabase) ...[
                const SizedBox(height: 12),
                const Text(
                  'This may take a few seconds',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnknownRoleScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  
  const _UnknownRoleScreen({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2D52).withOpacity(0.1),
              Colors.white,
              Colors.white,
              const Color(0xFF0F2D52).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Unable to determine user role',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2D52),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please contact support for assistance.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: onSignOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sign Out'),
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