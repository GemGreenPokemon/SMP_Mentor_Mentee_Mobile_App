import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentee/web_mentee_acknowledgment/web_mentee_acknowledgment_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_register/web_register_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/widgets/auth_wrapper.dart';

// Create test-specific mocks
class MockAuthService extends Mock implements AuthService {
  User? _currentUser;
  String? _userRole;
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);
  
  @override
  Future<String?> getUserRole({int maxRetries = 3, Duration retryDelay = const Duration(seconds: 2)}) async => _userRole;
  
  @override
  bool get isEmailVerified => true; // Skip email verification for test
  
  // Test helpers
  void setTestUser(User? user, String? role) {
    _currentUser = user;
    _userRole = role;
  }
}

class MockCloudFunctionService extends Mock implements CloudFunctionService {
  bool _hasAcknowledged = false;
  
  @override
  Future<Map<String, dynamic>> checkMenteeAcknowledgment() async {
    return {
      'hasAcknowledged': _hasAcknowledged,
      'requiresAcknowledgment': !_hasAcknowledged,
    };
  }
  
  @override
  Future<Map<String, dynamic>> submitMenteeAcknowledgment({
    String? fullName,
    String? studentId,
    String? email,
  }) async {
    _hasAcknowledged = true;
    return {
      'success': true,
      'message': 'Acknowledgment submitted successfully',
    };
  }
  
  void resetAcknowledgment() {
    _hasAcknowledged = false;
  }
}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-mentee-uid';
  
  @override
  String? get email => 'testmentee@ucmerced.edu';
  
  @override
  bool get emailVerified => true;
}

void main() {
  group('Mentee Registration → Acknowledgment Flow', () {
    late MockAuthService mockAuthService;
    late MockCloudFunctionService mockCloudFunctions;
    late MockUser mockUser;
    
    setUp(() {
      mockAuthService = MockAuthService();
      mockCloudFunctions = MockCloudFunctionService();
      mockUser = MockUser();
      
      // Reset state
      mockCloudFunctions.resetAcknowledgment();
    });
    
    testWidgets('New mentee sees acknowledgment screen after login', (tester) async {
      print('\n🧪 TEST: New mentee acknowledgment flow\n');
      
      // Setup: User is logged in as mentee but hasn't acknowledged
      mockAuthService.setTestUser(mockUser, 'mentee');
      
      // Build the app with mocked services
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>.value(value: mockAuthService),
              Provider<CloudFunctionService>.value(value: mockCloudFunctions),
            ],
            child: AuthWrapper(),
          ),
        ),
      );
      
      // Wait for auth check
      await tester.pumpAndSettle();
      
      // Verify: Should see acknowledgment screen
      print('✅ Checking for acknowledgment screen...');
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsOneWidget);
      expect(find.text('Mentee Acknowledgment'), findsOneWidget);
      
      print('✅ Acknowledgment screen displayed for new mentee!');
      
      // Find and fill the name field
      print('\n📝 Filling out acknowledgment form...');
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Test Mentee');
      
      // Check the acknowledgment checkbox
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      
      // Submit the form
      print('📤 Submitting acknowledgment...');
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Acknowledgment');
      expect(submitButton, findsOneWidget);
      
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      
      // Verify: Should now see dashboard
      print('\n✅ Checking for dashboard after acknowledgment...');
      expect(find.byType(WebMenteeDashboardScreen), findsOneWidget);
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsNothing);
      
      print('✅ Successfully navigated to dashboard after acknowledgment!');
    });
    
    testWidgets('Acknowledged mentee goes directly to dashboard', (tester) async {
      print('\n🧪 TEST: Already acknowledged mentee flow\n');
      
      // Setup: User is logged in and has already acknowledged
      mockAuthService.setTestUser(mockUser, 'mentee');
      mockCloudFunctions._hasAcknowledged = true; // Already acknowledged
      
      // Build the app
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>.value(value: mockAuthService),
              Provider<CloudFunctionService>.value(value: mockCloudFunctions),
            ],
            child: AuthWrapper(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify: Should go directly to dashboard
      print('✅ Checking for direct dashboard access...');
      expect(find.byType(WebMenteeDashboardScreen), findsOneWidget);
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsNothing);
      
      print('✅ Acknowledged mentee went directly to dashboard!');
    });
    
    testWidgets('Non-mentee users do not see acknowledgment', (tester) async {
      print('\n🧪 TEST: Non-mentee user flow\n');
      
      // Setup: User is logged in as mentor
      mockAuthService.setTestUser(mockUser, 'mentor');
      
      // Build the app
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>.value(value: mockAuthService),
              Provider<CloudFunctionService>.value(value: mockCloudFunctions),
            ],
            child: AuthWrapper(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify: Should not see acknowledgment screen
      print('✅ Checking that mentor skips acknowledgment...');
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsNothing);
      
      print('✅ Non-mentee users correctly skip acknowledgment!');
    });
  });
  
  print('''
  
  🎉 TEST SUMMARY:
  ===============
  These tests verify the core mentee registration flow:
  1. ✅ New mentees see acknowledgment screen
  2. ✅ Can fill and submit acknowledgment
  3. ✅ Navigate to dashboard after acknowledgment
  4. ✅ Returning mentees skip acknowledgment
  5. ✅ Non-mentees don't see acknowledgment
  
  No Firebase required! Just testing the UI flow.
  ''');
}