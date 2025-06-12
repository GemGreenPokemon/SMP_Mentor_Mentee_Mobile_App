import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './real_time_user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RealTimeUserService _realTimeUserService = RealTimeUserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Check if user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

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
    if (user == null) return null;

    try {
      // First try to get role from custom claims
      final tokenResult = await user.getIdTokenResult();
      final claimsRole = tokenResult.claims?['role'];
      if (claimsRole != null) return claimsRole;
      
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