import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/cloud_function_service.dart';
import '../services/real_time_user_service.dart' hide ConnectionState;
import '../screens/web/shared/web_login/web_login_screen.dart';
import '../screens/mobile/shared/login_screen.dart';
import '../screens/web/shared/web_email_verification/web_email_verification_screen.dart';
import '../screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart';
import '../screens/mobile/mentee/mentee_dashboard_screen.dart';
import '../screens/web/mentor/web_mentor_dashboard/web_mentor_dashboard_screen.dart';
import '../screens/mobile/mentor/mentor_dashboard_screen.dart';
import '../screens/web/coordinator/web_coordinator_dashboard_screen.dart';
import '../screens/mobile/coordinator/coordinator_dashboard_screen.dart';
import '../screens/mobile/shared/developer_home_screen.dart';
import '../utils/responsive.dart';
import '../utils/developer_session.dart';
import '../screens/web/mentee/web_mentee_acknowledgment/web_mentee_acknowledgment_screen.dart';
import '../screens/mobile/mentee/mentee_acknowledgment_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  bool _isLoading = true;
  String? _userRole;
  bool _isInitializingDatabase = false;
  bool _isCheckingRole = false;

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
    print('🔧🔧🔧 === AUTH STATE CHANGED ===');
    print('🔧 AuthWrapper: Auth state changed - user: ${user?.email}');
    print('🔧🔧🔧 Current state before change: _isLoading=$_isLoading, _userRole=$_userRole, _isCheckingRole=$_isCheckingRole');
    
    if (mounted) {
      if (user == null) {
        // User signed out
        print('🔧 AuthWrapper: User signed out');
        setState(() {
          _isLoading = false;
          _userRole = null;
          _isCheckingRole = false;
        });
      } else {
        // User signed in
        // Only check role if we don't already have one or if the user email changed
        if (_userRole == null || _authService.currentUser?.email != user.email) {
          print('🔧 AuthWrapper: User signed in, checking role...');
          print('🔧🔧🔧 Setting _isCheckingRole to true, will trigger rebuild');
          setState(() {
            _isCheckingRole = true;
          });
          await _checkCurrentUser();
        } else {
          print('🔧 AuthWrapper: Auth state changed but role already known ($_userRole), skipping role check');
        }
      }
    }
    print('🔧🔧🔧 === END AUTH STATE CHANGED ===');
  }

  Future<void> _checkCurrentUser() async {
    print('🔧 AuthWrapper: _checkCurrentUser called');
    try {
      final user = _authService.currentUser;
      
      if (user == null) {
        // No user signed in
        print('🔧 AuthWrapper: No user signed in');
        setState(() {
          _isLoading = false;
          _userRole = null;
          _isCheckingRole = false;
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
        print('🔧 AuthWrapper: Setting role to: $role');
        setState(() {
          _isLoading = false;
          _userRole = role;
          _isCheckingRole = false;
        });
      }
    } catch (e) {
      print('Error checking current user: $e');
      
      // Even if there's an error, check if this is the dev account
      final user = _authService.currentUser;
      final isDevAccount = user?.email == 'sunsetcoding.dev@gmail.com';
      
      if (mounted) {
        print('🔧 AuthWrapper: Error handler - setting role to: ${isDevAccount ? 'developer' : 'null'}');
        setState(() {
          _isLoading = false;
          // For dev account, ensure developer role even if there's an error
          _userRole = isDevAccount ? 'developer' : null;
          _isCheckingRole = false;
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

  Future<bool> _checkMenteeAcknowledgment() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return true; // Need acknowledgment if no user
      
      print('🔧 AuthWrapper: Checking acknowledgment for user: ${user.email}');
      
      // Use secure cloud function to check acknowledgment status
      final result = await _cloudFunctions.checkMenteeAcknowledgment();
      
      print('🔧 AuthWrapper: Cloud function raw result: $result');
      print('🔧 AuthWrapper: Result type: ${result.runtimeType}');
      print('🔧 AuthWrapper: Result keys: ${result.keys.toList()}');
      
      if (result['success'] == true) {
        final needsAcknowledgment = result['needsAcknowledgment'] ?? true;
        print('🔧 AuthWrapper: Acknowledgment check result: needsAcknowledgment=$needsAcknowledgment');
        print('🔧 AuthWrapper: acknowledgmentStatus: ${result['acknowledgmentStatus']}');
        return needsAcknowledgment;
      } else {
        print('🔧 AuthWrapper: Acknowledgment check failed: ${result['message']}');
        return true; // Default to needing acknowledgment on error
      }
    } catch (e) {
      print('Error checking mentee acknowledgment: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      return true; // Default to needing acknowledgment on error
    }
  }

  Future<bool> _checkMenteeAcknowledgmentDirect() async {
    print('🔧🔧🔧 _checkMenteeAcknowledgmentDirect STARTED');
    try {
      final user = _authService.currentUser;
      print('🔧🔧🔧 Current user: ${user?.email} (${user?.uid})');
      if (user == null) {
        print('🔧🔧🔧 No user found - returning true (needs acknowledgment)');
        return true;
      }
      
      print('🔧🔧🔧 Checking acknowledgment status for mentee...');
      
      try {
        // Query the database directly to check acknowledgment status
        final db = FirebaseFirestore.instance;
        final universityPath = _authService.universityPath;
        print('🔧🔧🔧 University path: $universityPath');
        
        // Try to find user by firebase_uid first
        print('🔧🔧🔧 Searching by firebase_uid: ${user.uid}');
        var querySnapshot = await db
            .collection(universityPath)
            .doc('data')
            .collection('users')
            .where('firebase_uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        
        print('🔧🔧🔧 Query by UID returned ${querySnapshot.docs.length} documents');
        
        // If not found by UID, try by email
        if (querySnapshot.docs.isEmpty && user.email != null) {
          print('🔧🔧🔧 Not found by UID, searching by email: ${user.email}');
          querySnapshot = await db
              .collection(universityPath)
              .doc('data')
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();
          print('🔧🔧🔧 Query by email returned ${querySnapshot.docs.length} documents');
        }
        
        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final acknowledgmentSigned = userData['acknowledgment_signed'] ?? 'no';
          final needsAcknowledgment = acknowledgmentSigned != 'yes';
          
          print('🔧🔧🔧 Found user in database');
          print('🔧🔧🔧 Document ID: ${querySnapshot.docs.first.id}');
          print('🔧🔧🔧 User type: ${userData['userType']}');
          print('🔧🔧🔧 acknowledgment_signed = "$acknowledgmentSigned"');
          print('🔧🔧🔧 needsAcknowledgment = $needsAcknowledgment');
          print('🔧🔧🔧 RETURNING: $needsAcknowledgment');
          
          return needsAcknowledgment;
        } else {
          print('🔧🔧🔧 User not found in database, defaulting to need acknowledgment');
          print('🔧🔧🔧 RETURNING: true (default)');
          return true; // Default to needing acknowledgment if user not found
        }
      } catch (e) {
        print('🔧🔧🔧 Error checking acknowledgment: $e');
        print('🔧🔧🔧 Stack trace: ${StackTrace.current}');
        print('🔧🔧🔧 RETURNING: true (error default)');
        return true; // Default to needing acknowledgment on error
      }
    } catch (e) {
      print('🔧🔧🔧 Error in _checkMenteeAcknowledgmentDirect: $e');
      print('🔧🔧🔧 RETURNING: true (outer error default)');
      return true; // Default to needing acknowledgment on error
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔧🔧🔧 === AUTHWRAPPER BUILD START ===');
    print('🔧 AuthWrapper build: _isLoading=$_isLoading, _isCheckingRole=$_isCheckingRole, _userRole=$_userRole');
    
    if (_isLoading) {
      print('🔧🔧🔧 Returning LoadingScreen because _isLoading=true');
      return _LoadingScreen(
        isInitializingDatabase: _isInitializingDatabase,
      );
    }

    final user = _authService.currentUser;
    print('🔧🔧🔧 Current user: ${user?.email}');

    // No user signed in - show login screen
    if (user == null) {
      print('🔧🔧🔧 No user - returning login screen');
      return Responsive.isWeb() ? const WebLoginScreen() : const LoginScreen();
    }

    // User signed in but email not verified - show email verification screen
    // Exception: bypass email verification for dev account
    final isDevAccount = user.email == 'sunsetcoding.dev@gmail.com';
    if (!_authService.isEmailVerified && !isDevAccount) {
      print('🔧🔧🔧 Email not verified - returning email verification screen');
      return const EmailVerificationScreen();
    }

    // If we're still checking the role after login, show loading
    if (_isCheckingRole) {
      print('🔧 AuthWrapper: Still checking role, showing loading screen');
      print('🔧🔧🔧 Returning LoadingScreen because _isCheckingRole=true');
      return _LoadingScreen(
        isInitializingDatabase: _isInitializingDatabase,
      );
    }

    // User signed in and email verified - navigate based on role
    print('🔧🔧🔧 Calling _buildDashboardForRole with role: $_userRole');
    final widget = _buildDashboardForRole(_userRole);
    print('🔧🔧🔧 _buildDashboardForRole returned: ${widget.runtimeType}');
    print('🔧🔧🔧 === AUTHWRAPPER BUILD END ===');
    return widget;
  }

  Widget _buildDashboardForRole(String? role) {
    print('🔧 AuthWrapper: _buildDashboardForRole called with role: $role');
    print('🔧 AuthWrapper: Stack trace: ${StackTrace.current}');
    
    // Special handling for dev account - always grant developer access
    final user = _authService.currentUser;
    final isDevAccount = user?.email == 'sunsetcoding.dev@gmail.com';
    
    if (isDevAccount) {
      print('🔧 AuthWrapper: Dev account detected, returning DeveloperHomeScreen');
      return const DeveloperHomeScreen();
    }
    
    switch (role?.toLowerCase()) {
      case 'mentee':
        print('🔧 AuthWrapper: MENTEE CASE - Starting acknowledgment check...');
        // Check if acknowledgment is needed for mentee
        return FutureBuilder<bool>(
          future: _checkMenteeAcknowledgmentDirect(),
          builder: (context, snapshot) {
            print('🔧 AuthWrapper: FutureBuilder state: ${snapshot.connectionState}');
            print('🔧 AuthWrapper: FutureBuilder hasData: ${snapshot.hasData}');
            print('🔧 AuthWrapper: FutureBuilder data: ${snapshot.data}');
            print('🔧 AuthWrapper: FutureBuilder error: ${snapshot.error}');
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('🔧 AuthWrapper: FutureBuilder waiting - showing loading screen');
              return const _LoadingScreen(isInitializingDatabase: false);
            }
            
            final needsAcknowledgment = snapshot.data ?? true;
            print('🔧 AuthWrapper: needsAcknowledgment resolved to: $needsAcknowledgment');
            
            if (needsAcknowledgment) {
              print('🔧 AuthWrapper: Mentee needs acknowledgment - SHOWING ACKNOWLEDGMENT SCREEN');
              print('🔧 AuthWrapper: Is web: ${Responsive.isWeb()}');
              final widget = Responsive.isWeb() 
                  ? const WebMenteeAcknowledgmentScreen() 
                  : const MenteeAcknowledgmentScreen();
              print('🔧 AuthWrapper: Returning widget: ${widget.runtimeType}');
              return widget;
            } else {
              print('🔧 AuthWrapper: Mentee acknowledged - SHOWING DASHBOARD');
              print('🔧 AuthWrapper: Is web: ${Responsive.isWeb()}');
              final widget = Responsive.isWeb() 
                  ? const WebMenteeDashboardScreen() 
                  : const MenteeDashboardScreen();
              print('🔧 AuthWrapper: Returning widget: ${widget.runtimeType}');
              return widget;
            }
          },
        );
      case 'mentor':
        print('🔧 AuthWrapper: Mentor role detected, returning mentor dashboard');
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
        print('🔧 AuthWrapper: WARNING - Unknown role, showing error screen. Role was: $role');
        print('🔧 AuthWrapper: Stack trace:');
        print(StackTrace.current);
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