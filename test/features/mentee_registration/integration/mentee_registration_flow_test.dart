import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/firebase_options.dart';

// IMPORTANT: Run these tests with Firebase Emulator running
// Start emulators: firebase emulators:start
void main() {
  group('Mentee Registration Flow - Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late AuthService authService;
    
    setUpAll(() async {
      // Initialize Firebase for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Connect to emulators
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      
      // Connect to local emulators
      await auth.useAuthEmulator('localhost', 9099);
      firestore.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      
      authService = AuthService();
    });

    tearDown(() async {
      // Clean up after each test
      final user = auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    });

    test('Complete mentee registration flow with Firebase Emulator', () async {
      // 1. Add test user to whitelist
      print('Step 1: Adding test user to whitelist...');
      final testEmail = 'testmentee_${DateTime.now().millisecondsSinceEpoch}@ucmerced.edu';
      await firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('users')
          .add({
        'name': 'Test Mentee',
        'email': testEmail,
        'userType': 'mentee',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // 2. Verify name is in whitelist
      print('Step 2: Verifying name is in whitelist...');
      final isApproved = await authService.isNameApprovedForRegistration('Test Mentee');
      expect(isApproved, isTrue, reason: 'Name should be approved in whitelist');
      
      // 3. Register the user
      print('Step 3: Registering user...');
      final userCredential = await authService.registerWithNameValidation(
        email: testEmail,
        password: 'testPassword123',
        name: 'Test Mentee',
      );
      expect(userCredential?.user, isNotNull, reason: 'User should be created');
      expect(userCredential?.user?.email, equals(testEmail));
      
      // 4. Wait for custom claims to be set
      print('Step 4: Waiting for custom claims...');
      await authService.syncUserClaims();
      
      // Get fresh ID token with claims
      final idToken = await userCredential?.user?.getIdTokenResult(true);
      print('Custom claims: ${idToken?.claims}');
      expect(idToken?.claims?['role'], equals('mentee'), 
          reason: 'User should have mentee role in custom claims');
      
      // 5. Check acknowledgment is required
      print('Step 5: Checking if acknowledgment is required...');
      final cloudFunctions = CloudFunctionService();
      final acknowledgmentStatus = await cloudFunctions.checkMenteeAcknowledgment();
      print('Acknowledgment status: $acknowledgmentStatus');
      expect(acknowledgmentStatus['needsAcknowledgment'], isTrue,
          reason: 'New mentee should need acknowledgment');
      
      // 6. Submit acknowledgment
      print('Step 6: Submitting acknowledgment...');
      final submitResult = await cloudFunctions.submitMenteeAcknowledgment(
        fullName: 'Test Mentee',
      );
      print('Submit result: $submitResult');
      expect(submitResult['success'], isTrue,
          reason: 'Acknowledgment submission should succeed');
      
      // 7. Verify user can now access dashboard
      print('Step 7: Verifying acknowledgment is complete...');
      final acknowledgmentStatusAfter = await cloudFunctions.checkMenteeAcknowledgment();
      print('Acknowledgment status after: $acknowledgmentStatusAfter');
      expect(acknowledgmentStatusAfter['needsAcknowledgment'], isFalse,
          reason: 'Mentee should not need acknowledgment after submission');
      
      print('✅ Complete mentee registration flow test passed!');
    });

    test('Registration fails for name not in whitelist', () async {
      print('Testing registration failure for non-whitelisted name...');
      
      // 1. Verify name is NOT in whitelist
      final isApproved = await authService.isNameApprovedForRegistration('Not In Whitelist');
      expect(isApproved, isFalse, reason: 'Non-whitelisted name should not be approved');
      
      // 2. Try to register with non-whitelisted name
      try {
        await authService.registerWithNameValidation(
          email: 'notapproved@ucmerced.edu',
          password: 'testPassword123',
          name: 'Not In Whitelist',
        );
        fail('Registration should have thrown an exception');
      } catch (e) {
        print('Expected error: $e');
        expect(e.toString(), contains('not found in the whitelist'));
      }
      
      print('✅ Non-whitelisted registration correctly rejected!');
    });

    test('Mentee cannot bypass acknowledgment', () async {
      print('Testing acknowledgment bypass prevention...');
      
      // 1. Add test user to whitelist and register
      final testEmail = 'testbypass_${DateTime.now().millisecondsSinceEpoch}@ucmerced.edu';
      await firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('users')
          .add({
        'name': 'Bypass Test Mentee',
        'email': testEmail,
        'userType': 'mentee',
      });
      
      final userCredential = await authService.registerWithNameValidation(
        email: testEmail,
        password: 'testPassword123',
        name: 'Bypass Test Mentee',
      );
      
      // Wait for claims
      await authService.syncUserClaims();
      
      // 2. Verify acknowledgment is required
      final cloudFunctions = CloudFunctionService();
      final acknowledgmentStatus = await cloudFunctions.checkMenteeAcknowledgment();
      expect(acknowledgmentStatus['needsAcknowledgment'], isTrue,
          reason: 'New mentee should need acknowledgment');
      
      // 3. Try to manually update the user document (simulating bypass attempt)
      // In a real app, this would be blocked by security rules
      try {
        await firestore
            .collection('california_merced_uc_merced')
            .doc('data')
            .collection('users')
            .where('email', isEqualTo: testEmail)
            .get()
            .then((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            // Try to manually set acknowledgment (this should be blocked by security rules)
            await snapshot.docs.first.reference.update({
              'hasCompletedAcknowledgment': true,
              'acknowledgmentSigned': 'yes',
            });
          }
        });
      } catch (e) {
        print('Expected security rule violation: $e');
      }
      
      // 4. Verify acknowledgment is STILL required (bypass didn't work)
      final statusAfterBypass = await cloudFunctions.checkMenteeAcknowledgment();
      expect(statusAfterBypass['needsAcknowledgment'], isTrue,
          reason: 'Acknowledgment should still be required after bypass attempt');
      
      print('✅ Acknowledgment bypass prevention working correctly!');
    });
  });
}