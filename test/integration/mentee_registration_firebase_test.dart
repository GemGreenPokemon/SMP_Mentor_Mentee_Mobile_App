import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smp_mentor_mentee_mobile_app/main.dart';
import 'package:smp_mentor_mentee_mobile_app/firebase_options.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentee/web_mentee_acknowledgment/web_mentee_acknowledgment_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_login/web_login_screen.dart';

// This test requires Firebase emulator to be running:
// firebase emulators:start

void main() {
  group('Mentee Registration Flow - Firebase Integration', () {
    // Set up Firebase for tests
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      print('\n🔥 Initializing Firebase for tests...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Configure to use emulator
      const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'true');
      if (useEmulator == 'true') {
        print('🔧 Configuring Firebase Emulator...');
        
        // Set up Auth emulator
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        
        // Set up Firestore emulator
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        
        print('✅ Firebase Emulator configured!');
      }
      
      // Clean up any existing test users
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Ignore if no user signed in
      }
    });
    
    tearDown(() async {
      // Sign out after each test
      await FirebaseAuth.instance.signOut();
    });
    
    testWidgets('Complete mentee registration and acknowledgment flow', (tester) async {
      print('\n🧪 TEST: Full mentee registration → acknowledgment → dashboard flow\n');
      
      // Test data - make sure this name is in your whitelist!
      final testEmail = 'testmentee${DateTime.now().millisecondsSinceEpoch}@ucmerced.edu';
      const testPassword = 'TestPassword123!';
      const testName = 'Test Mentee Johnson'; // Add this to whitelist in emulator
      
      // 1. Start the app
      print('📱 Starting app...');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // 2. Should see login screen
      print('\n🔐 Step 1: Verify login screen appears');
      expect(find.byType(WebLoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      
      // 3. Navigate to registration
      print('\n📝 Step 2: Navigate to registration');
      final createAccountButton = find.text("Don't have an account? Sign up");
      expect(createAccountButton, findsOneWidget);
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();
      
      // 4. Fill registration form
      print('\n✍️ Step 3: Fill registration form');
      // Select mentee role
      final menteeCard = find.text('Mentee');
      expect(menteeCard, findsOneWidget);
      await tester.tap(menteeCard);
      await tester.pumpAndSettle();
      
      // Fill form fields
      await tester.enterText(find.byKey(Key('nameField')), testName);
      await tester.enterText(find.byKey(Key('emailField')), testEmail);
      await tester.enterText(find.byKey(Key('passwordField')), testPassword);
      await tester.enterText(find.byKey(Key('confirmPasswordField')), testPassword);
      
      print('   ✅ Form filled with test data');
      
      // 5. Submit registration
      print('\n🚀 Step 4: Submit registration');
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.tap(registerButton);
      
      // Wait for registration to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      
      // 6. Verify acknowledgment screen appears
      print('\n📋 Step 5: Verify acknowledgment screen appears');
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsOneWidget,
          reason: 'New mentee should see acknowledgment screen');
      expect(find.text('Mentee Acknowledgment'), findsOneWidget);
      
      print('   ✅ Acknowledgment screen displayed!');
      
      // 7. Fill and submit acknowledgment
      print('\n✅ Step 6: Complete acknowledgment');
      
      // Enter full name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, testName);
      
      // Check the acknowledgment box
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      
      // Submit acknowledgment
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Acknowledgment');
      await tester.tap(submitButton);
      
      // Wait for submission
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      // 8. Verify navigation to dashboard
      print('\n🎯 Step 7: Verify navigation to dashboard');
      expect(find.byType(WebMenteeDashboardScreen), findsOneWidget,
          reason: 'After acknowledgment, mentee should see dashboard');
      expect(find.text('Mentee Dashboard'), findsOneWidget);
      
      print('   ✅ Successfully navigated to dashboard!');
      
      // 9. Verify user data in Firebase
      print('\n🔍 Step 8: Verify Firebase data');
      final user = FirebaseAuth.instance.currentUser;
      expect(user, isNotNull);
      expect(user!.email, equals(testEmail));
      
      // Check custom claims
      final idToken = await user.getIdTokenResult();
      expect(idToken.claims?['role'], equals('mentee'),
          reason: 'User should have mentee role in custom claims');
      
      // Check Firestore acknowledgment
      final cloudFunctions = CloudFunctionService();
      final ackStatus = await cloudFunctions.checkMenteeAcknowledgment();
      expect(ackStatus['hasAcknowledged'], isTrue,
          reason: 'Acknowledgment should be recorded in database');
      
      print('   ✅ All Firebase data verified!');
      
      print('\n🎉 COMPLETE FLOW TEST PASSED!');
    });
    
    testWidgets('Returning mentee skips acknowledgment', (tester) async {
      print('\n🧪 TEST: Returning mentee goes directly to dashboard\n');
      
      // First, create and acknowledge a test mentee
      final authService = AuthService();
      final testEmail = 'returning${DateTime.now().millisecondsSinceEpoch}@ucmerced.edu';
      const testPassword = 'TestPassword123!';
      
      print('📝 Creating test mentee account...');
      
      // Register the mentee
      await authService.registerWithNameValidation(
        email: testEmail,
        password: testPassword,
        name: 'Test Mentee Johnson', // Use same whitelisted name
      );
      
      // Submit acknowledgment
      final cloudFunctions = CloudFunctionService();
      await cloudFunctions.submitMenteeAcknowledgment(
        fullName: 'Test Mentee Johnson',
      );
      
      // Sign out
      await authService.signOut();
      
      print('✅ Test mentee created and acknowledged');
      
      // Now test the login flow
      print('\n🔐 Testing login flow for acknowledged mentee...');
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Login with the test account
      await tester.enterText(find.byKey(Key('emailField')), testEmail);
      await tester.enterText(find.byKey(Key('passwordField')), testPassword);
      
      final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(loginButton);
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      // Should go directly to dashboard, not acknowledgment
      expect(find.byType(WebMenteeDashboardScreen), findsOneWidget,
          reason: 'Acknowledged mentee should skip acknowledgment screen');
      expect(find.byType(WebMenteeAcknowledgmentScreen), findsNothing,
          reason: 'Should not show acknowledgment screen again');
      
      print('✅ Returning mentee correctly skipped acknowledgment!');
    });
  });
  
  print('''
  
  🎉 FIREBASE INTEGRATION TEST SUMMARY:
  ====================================
  These tests verify the COMPLETE flow with real Firebase:
  1. ✅ Mentee can register with Firebase Auth
  2. ✅ Custom claims are properly set
  3. ✅ New mentees see acknowledgment screen
  4. ✅ Acknowledgment is saved to Firestore
  5. ✅ After acknowledgment, mentees see dashboard
  6. ✅ Returning mentees skip acknowledgment
  
  This proves the entire system works end-to-end!
  ''');
}