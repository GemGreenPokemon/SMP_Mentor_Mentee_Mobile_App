import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './real_time_user_service.dart';
import './cloud_function_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Connect to Auth emulator when USE_EMULATOR is set or in debug mode
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    
    if (useEmulator == 'true' || kDebugMode) {
      try {
        _auth.useAuthEmulator('127.0.0.1', 9099);
        print('🔐 Auth service connected to emulator at 127.0.0.1:9099');
      } catch (e) {
        // Already connected or emulator not available
        print('⚠️ Auth emulator connection failed or already connected: $e');
      }
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Check if user's email is verified
  bool get isEmailVerified {
    // Bypass email verification in debug mode (emulator)
    if (kDebugMode) {
      print('📧 Email verification bypassed in debug mode');
      return true;
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Get university path (hardcoded for now, can be made dynamic later)
  String get universityPath => 'california_merced_uc_merced';

  // Check if name is approved for registration (NAME-ONLY WHITELIST)
  Future<bool> isNameApprovedForRegistration(String name) async {
    try {
      print('🔍 === NAME VALIDATION DEBUG ===');
      print('🔍 Searching for name: "${name.trim()}"');
      print('🔍 Collection path: $universityPath/data/users');
      print('🔍 University path resolved to: $universityPath');
      
      // First, let's see what's actually in the database
      print('🔍 Getting all users to see what names exist...');
      final allUsersSnapshot = await _firestore
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .get();
      
      print('🔍 Total documents in users collection: ${allUsersSnapshot.docs.length}');
      
      if (allUsersSnapshot.docs.isNotEmpty) {
        print('🔍 All names in database:');
        for (var i = 0; i < allUsersSnapshot.docs.length; i++) {
          final doc = allUsersSnapshot.docs[i];
          final data = doc.data();
          final docName = data['name'];
          print('🔍   Document $i: ID="${doc.id}", name="$docName", type=${docName.runtimeType}');
        }
      } else {
        print('🔍 ❌ No documents found in users collection!');
      }
      
      // Now do the specific name search
      print('🔍 Performing specific name search...');
      final usersSnapshot = await _firestore
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .where('name', isEqualTo: name.trim())
          .get();
      
      print('🔍 Specific name search results: ${usersSnapshot.docs.length} documents found');
      
      if (usersSnapshot.docs.isNotEmpty) {
        print('🔍 ✅ Name "${name.trim()}" found in database');
        usersSnapshot.docs.forEach((doc) {
          print('🔍   Matching document: ${doc.id} -> ${doc.data()}');
        });
      } else {
        print('🔍 ❌ Name "${name.trim()}" NOT found in database');
        
        // Check for case-insensitive matches
        final allNames = allUsersSnapshot.docs.map((doc) => doc.data()['name'] as String?).where((n) => n != null).toList();
        final lowercaseSearchName = name.trim().toLowerCase();
        final caseInsensitiveMatches = allNames.where((n) => n!.toLowerCase() == lowercaseSearchName).toList();
        
        if (caseInsensitiveMatches.isNotEmpty) {
          print('🔍 ⚠️ Found case-insensitive matches: $caseInsensitiveMatches');
        } else {
          print('🔍 ❌ No case-insensitive matches found either');
        }
      }
      
      print('🔍 === END NAME VALIDATION DEBUG ===');
      
      return usersSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('🔍 ❌ Error checking name approval: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Register user with name-only whitelist validation
  Future<UserCredential?> registerWithNameValidation({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Check if name is approved (WHITELIST VALIDATION)
      final isApproved = await isNameApprovedForRegistration(name);
      if (!isApproved) {
        throw FirebaseAuthException(
          code: 'name-not-approved',
          message: 'Your name is not on the approved list. Please contact your coordinator.',
        );
      }

      // Step 2: Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 3: Send email verification
      await sendEmailVerification();

      // Step 4: Update user record with Firebase Auth UID
      await _updateUserRecordWithAuthUID(name, credential.user!.uid);

      // Step 5: Set custom claims for the new user
      try {
        print('🔐 === SETTING CUSTOM CLAIMS ON REGISTRATION ===');
        print('🔐 User UID: ${credential.user!.uid}');
        print('🔐 User email: ${credential.user!.email}');
        print('🔐 User name: $name');
        
        // Call cloud function to set claims
        print('🔐 Calling setCustomClaimsOnRegistration cloud function...');
        final result = await _cloudFunctions.setCustomClaimsOnRegistration(
          uid: credential.user!.uid,
        );
        
        print('🔐 Cloud function result: $result');
        
        if (result['success'] == true) {
          print('🔐 ✅ Cloud function returned success');
          print('🔐 Claims set: ${result['claims']}');
          print('🔐 Debug info: ${result['debug']}');
          
          // Force token refresh to get the new claims
          print('🔐 Forcing token refresh to apply new claims...');
          await credential.user!.getIdToken(true);
          
          // Wait longer for claims to propagate (Firebase can take 3-5 seconds)
          // This delay is necessary because Firebase Auth custom claims need time
          // to propagate through their distributed system after being set
          print('🔐 Waiting 5 seconds for claims to propagate through Firebase...');
          await Future.delayed(const Duration(seconds: 5));
          
          // Implement retry mechanism for claims verification
          bool claimsVerified = false;
          int retryCount = 0;
          const maxRetries = 3;
          const retryDelay = Duration(seconds: 2);
          
          while (!claimsVerified && retryCount < maxRetries) {
            retryCount++;
            print('🔐 Verifying claims (attempt $retryCount/$maxRetries)...');
            
            // Get fresh token result
            final tokenResult = await credential.user!.getIdTokenResult(true);
            
            // Log detailed claims information
            print('🔐 Token after refresh - all claims: ${tokenResult.claims}');
            print('🔐 Token after refresh - custom claims found:');
            print('🔐   - role: ${tokenResult.claims?['role'] ?? 'NOT SET'}');
            print('🔐   - university_path: ${tokenResult.claims?['university_path'] ?? 'NOT SET'}');
            print('🔐   - email: ${tokenResult.claims?['email']}');
            print('🔐   - email_verified: ${tokenResult.claims?['email_verified']}');
            
            if (tokenResult.claims?['role'] != null) {
              claimsVerified = true;
              print('🔐 ✅ SUCCESS: Custom claims are now active!');
              print('🔐   - Role: ${tokenResult.claims?['role']}');
              print('🔐   - University Path: ${tokenResult.claims?['university_path']}');
            } else {
              print('🔐 ⚠️ Claims not yet available, attempt $retryCount failed');
              
              if (retryCount < maxRetries) {
                print('🔐 Waiting ${retryDelay.inSeconds} seconds before retry...');
                await Future.delayed(retryDelay);
                
                // Force another token refresh
                await credential.user!.getIdToken(true);
              }
            }
          }
          
          if (!claimsVerified) {
            print('🔐 ⚠️ WARNING: Claims verification failed after $maxRetries attempts');
            print('🔐 Expected claims were set by cloud function: ${result['claims']}');
            print('🔐 But they have not propagated to the ID token yet');
            print('🔐 They should be available on next login');
          }
        } else {
          print('🔐 ❌ Cloud function returned failure: ${result['message'] ?? 'Unknown error'}');
        }
        
        print('🔐 === END SETTING CUSTOM CLAIMS ===');
      } catch (claimsError) {
        print('🔐 ❌ ERROR setting custom claims during registration: $claimsError');
        print('🔐 Error type: ${claimsError.runtimeType}');
        // Don't throw - registration was successful, claims are just missing
        // User can still use the app, just might need to sync claims on login
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Sync custom claims after successful login to ensure proper permissions
      if (credential.user != null) {
        try {
          print('🔐 === CUSTOM CLAIMS SYNC START ===');
          print('🔐 User logged in: ${credential.user!.email} (${credential.user!.uid})');
          
          // Check current claims before sync
          final tokenBeforeSync = await credential.user!.getIdTokenResult();
          print('🔐 Claims BEFORE sync: ${tokenBeforeSync.claims}');
          print('🔐 Role in claims BEFORE: ${tokenBeforeSync.claims?['role'] ?? 'NOT SET'}');
          
          // Only sync if role is not already set (skip for super_admin who already has claims)
          final existingRole = tokenBeforeSync.claims?['role'];
          if (existingRole == null) {
            print('🔐 No role found, calling syncUserClaimsOnLogin...');
            final result = await _cloudFunctions.syncUserClaimsOnLogin();
            
            if (result['success'] == true) {
              print('🔐 ✅ Cloud function returned success');
              print('🔐 Claims set by cloud function: ${result['claims']}');
              
              // Force aggressive token refresh
              print('🔐 Forcing token refresh...');
              await credential.user!.getIdToken(true);
              
              // Wait a bit for claims to propagate
              await Future.delayed(const Duration(seconds: 1));
              
              // Get new token and verify claims
              final tokenAfterSync = await credential.user!.getIdTokenResult(true);
              print('🔐 Claims AFTER sync: ${tokenAfterSync.claims}');
              print('🔐 Role in claims AFTER: ${tokenAfterSync.claims?['role'] ?? 'STILL NOT SET!'}');
              
              if (tokenAfterSync.claims?['role'] == null) {
                print('🔐 ❌ WARNING: Claims still not set after sync!');
              } else {
                print('🔐 ✅ SUCCESS: Role is now ${tokenAfterSync.claims?['role']}');
              }
            } else {
              print('🔐 ❌ Claims sync failed: ${result['message'] ?? result['error'] ?? 'Unknown error'}');
            }
          } else {
            print('🔐 ✅ User already has role: $existingRole, skipping sync');
          }
          print('🔐 === CUSTOM CLAIMS SYNC END ===');
        } catch (claimsError) {
          print('🔐 ❌ Error syncing claims: $claimsError');
          print('🔐 Error type: ${claimsError.runtimeType}');
          // Don't fail login if claims sync fails
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Auth error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        print('Email verification sent to ${user.email}');
      } catch (e) {
        print('Error sending email verification: $e');
        throw e;
      }
    }
  }

  // Reload user to check email verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw e;
    }
  }

  // Helper method to update user record with Firebase Auth UID
  Future<void> _updateUserRecordWithAuthUID(String name, String uid) async {
    try {
      print('🔧 === UPDATING USER RECORD WITH FIREBASE UID ===');
      print('🔧 Looking for user with name: "${name.trim()}"');
      print('🔧 Firebase Auth UID to assign: $uid');
      print('🔧 Collection path: $universityPath/data/users');
      
      // Find the user document by name
      final usersSnapshot = await _firestore
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .where('name', isEqualTo: name.trim())
          .get();

      print('🔧 Found ${usersSnapshot.docs.length} documents matching name "${name.trim()}"');

      if (usersSnapshot.docs.isNotEmpty) {
        // Update the first matching user document with the Firebase Auth UID
        final userDoc = usersSnapshot.docs.first;
        print('🔧 Updating document ${userDoc.id}');
        print('🔧 Current document data: ${userDoc.data()}');
        
        await userDoc.reference.update({
          'firebase_uid': uid,
          'account_created_at': FieldValue.serverTimestamp(),
          'email_verified': false,
        });
        
        print('🔧 ✅ Successfully updated user record with Firebase Auth UID: $uid');
        
        // Verify the update worked
        final updatedDoc = await userDoc.reference.get();
        if (updatedDoc.exists) {
          final updatedData = updatedDoc.data()!;
          print('🔧 Verification - Updated document now contains:');
          print('🔧   firebase_uid: ${updatedData['firebase_uid']}');
          print('🔧   account_created_at: ${updatedData['account_created_at']}');
          print('🔧   email_verified: ${updatedData['email_verified']}');
        }
      } else {
        print('🔧 ❌ No user found with name "${name.trim()}" to update with Firebase UID');
        
        // Let's see what names are actually in the database
        final allUsersSnapshot = await _firestore
            .collection(universityPath)
            .doc('data')
            .collection('users')
            .get();
        print('🔧 Available names in database:');
        allUsersSnapshot.docs.forEach((doc) {
          print('🔧   "${doc.data()['name']}"');
        });
      }
      
      print('🔧 === END UPDATING USER RECORD ===');
    } catch (e) {
      print('🔧 ❌ Error updating user record with UID: $e');
      print('🔧 Error type: ${e.runtimeType}');
      print('🔧 Stack trace: ${StackTrace.current}');
      // Don't throw here - registration was successful, this is just metadata
    }
  }

  // Get user role from Firestore with retry logic and connection waiting
  Future<String?> getUserRole({int maxRetries = 3, Duration retryDelay = const Duration(seconds: 2)}) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('🔧 getUserRole: No current user');
      return null;
    }

    try {
      print('🔧 === GET USER ROLE START ===');
      print('🔧 Getting role for user: ${user.email} (${user.uid})');
      
      // First try to get role from custom claims
      final tokenResult = await user.getIdTokenResult();
      print('🔧 Token claims: ${tokenResult.claims}');
      final claimsRole = tokenResult.claims?['role'];
      
      if (claimsRole != null) {
        print('🔧 ✅ Role found in custom claims: $claimsRole');
        print('🔧 === GET USER ROLE END ===');
        return claimsRole;
      }
      
      print('🔧 ⚠️ No role in custom claims, falling back to database lookup');
      
      // For database lookup, wait for connection and implement retry logic
      return await _getUserRoleFromDatabase(user, maxRetries: maxRetries, retryDelay: retryDelay);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Helper method to get user role from database with retry logic
  Future<String?> _getUserRoleFromDatabase(User user, {int maxRetries = 3, Duration retryDelay = const Duration(seconds: 2)}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔧 Attempt $attempt/$maxRetries: Getting user role from database');
        
        // Wait for database connection before attempting query
        final isConnected = await _realTimeUserService.waitForConnection(
          timeout: const Duration(seconds: 10)
        );
        
        if (!isConnected) {
          print('🔧 Database connection not available, attempt $attempt failed');
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          } else {
            print('🔧 All attempts failed - database connection not available');
            return null;
          }
        }
        
        print('🔧 Database connected, proceeding with role lookup');

        // Fallback: get role from Firestore user document
        print('🔧 Searching in subcollection: $universityPath → doc(data) → collection(users)');
        print('🔧 Looking for firebase_uid: ${user.uid}');
        
        // First try by firebase_uid
        var usersSnapshot = await _firestore
            .collection(universityPath)
            .doc('data')
            .collection('users')
            .where('firebase_uid', isEqualTo: user.uid)
            .get();
            
        print('🔧 firebase_uid search returned ${usersSnapshot.docs.length} documents');

        if (usersSnapshot.docs.isNotEmpty) {
          final userData = usersSnapshot.docs.first.data();
          return userData['userType'] as String?;
        }

        // Second fallback: search by email if firebase_uid search failed
        print('🔧 firebase_uid search failed, trying email fallback for: ${user.email}');
        
        // Try exact email match first
        usersSnapshot = await _firestore
            .collection(universityPath)
            .doc('data')
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        
        print('🔧 Email search returned ${usersSnapshot.docs.length} documents');
          
        // Debug: If still not found, let's see what's actually in the database  
        if (usersSnapshot.docs.isEmpty) {
          print('🔧 Exact email match failed. Checking all user documents...');
          final allUsersSnapshot = await _firestore
              .collection(universityPath)
              .doc('data')
              .collection('users')
              .get();
          print('🔧 Total users in database: ${allUsersSnapshot.docs.length}');
          for (var doc in allUsersSnapshot.docs.take(5)) { // Show first 5
            final data = doc.data();
            print('🔧 User doc ID: ${doc.id}');
            print('🔧 User data: name=${data['name']}, email=${data['email']}, userType=${data['userType']}, firebase_uid=${data['firebase_uid']}');
          }
          
          // Also check if there's a document with your specific firebase_uid
          print('🔧 Checking if ANY document has firebase_uid: ${user.uid}');
          final uidCheckSnapshot = await _firestore
              .collection(universityPath)
              .doc('data')
              .collection('users')
              .get();
          for (var doc in uidCheckSnapshot.docs) {
            final data = doc.data();
            if (data['firebase_uid'] == user.uid) {
              print('🔧 FOUND IT! Document ${doc.id} has matching firebase_uid but query failed');
              print('🔧 Data: ${data.toString()}');
            }
          }
        }

        if (usersSnapshot.docs.isNotEmpty) {
          final userData = usersSnapshot.docs.first.data();
          final userType = userData['userType'] as String?;
          
          // Update the record with firebase_uid for future lookups
          try {
            await usersSnapshot.docs.first.reference.update({
              'firebase_uid': user.uid,
              'email_verified': user.emailVerified,
            });
            print('🔧 Updated user record with missing firebase_uid');
          } catch (updateError) {
            print('🔧 Failed to update firebase_uid: $updateError');
          }
          
          return userType;
        }
        
        // If we reach here, user not found in this attempt
        print('🔧 User not found in attempt $attempt');
        if (attempt < maxRetries) {
          print('🔧 Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        }
        
      } catch (e) {
        print('🔧 Error in attempt $attempt: $e');
        if (attempt < maxRetries) {
          print('🔧 Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          print('🔧 All attempts failed with error: $e');
          rethrow;
        }
      }
    }
    
    print('🔧 All retry attempts exhausted, returning null');
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get ID token for cloud function calls
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Check if user has super admin role
  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      final tokenResult = await user.getIdTokenResult();
      final claims = tokenResult.claims;
      return claims?['role'] == 'super_admin';
    }
    return false;
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}