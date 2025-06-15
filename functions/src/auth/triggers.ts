import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUniversityCollection } from '../utils/database';
import { setUserClaims } from '../utils/auth';

/**
 * Firebase Auth trigger: Set custom claims when user logs in
 * This ensures users have proper role claims for API access
 */
export const setClaimsOnLogin = functions.auth.user().onCreate(async (user) => {
  try {
    console.log(`🔐 New user created: ${user.uid} (${user.email})`);
    
    // For now, we'll skip setting claims on user creation since the user
    // might not exist in our database yet. Claims will be set on first login.
    
  } catch (error) {
    console.error('Error in user creation trigger:', error);
  }
});

/**
 * HTTP function to set claims for existing user when they login
 * This will be called by the frontend when user logs in
 */
export const syncClaimsOnLogin = functions.https.onCall(async (data, context) => {
  try {
    console.log('🔐 === SYNC CLAIMS ON LOGIN START ===');
    
    if (!context.auth) {
      console.log('🔐 ❌ No authentication context');
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const userUid = context.auth.uid;
    const userEmail = context.auth.token.email;
    
    console.log(`🔐 Syncing claims for user: ${userUid} (${userEmail})`);

    // Check if user already has claims
    const userRecord = await admin.auth().getUser(userUid);
    const existingClaims = userRecord.customClaims;
    
    console.log(`🔐 Existing claims for user: ${JSON.stringify(existingClaims || {})}`);
    
    // Special handling for super_admin - they already have claims set
    if (existingClaims && existingClaims.role === 'super_admin') {
      console.log(`✅ User ${userUid} is super_admin - claims already properly set`);
      return {
        success: true,
        message: 'Super admin claims already set',
        claims: existingClaims
      };
    }
    
    if (existingClaims && existingClaims.role && existingClaims.university_path) {
      console.log(`✅ User ${userUid} already has claims: role=${existingClaims.role}, university=${existingClaims.university_path}`);
      return {
        success: true,
        message: 'Claims already set',
        claims: existingClaims
      };
    }
    
    console.log('🔐 No existing claims found, need to fetch from database');

    // Search for user in database to get their role
    const universityPath = 'california_merced_uc_merced'; // Default university for now
    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Try to find user by firebase_uid first
    console.log(`🔐 Searching for user by firebase_uid: ${userUid}`);
    let userSnapshot = await usersCollection
      .where('firebase_uid', '==', userUid)
      .get();
    
    console.log(`🔐 Search by firebase_uid returned ${userSnapshot.size} documents`);
    
    // If not found by firebase_uid, try by email
    if (userSnapshot.empty && userEmail) {
      console.log(`🔐 Not found by firebase_uid, trying email: ${userEmail}`);
      userSnapshot = await usersCollection
        .where('email', '==', userEmail)
        .get();
      console.log(`🔐 Search by email returned ${userSnapshot.size} documents`);
    }

    if (userSnapshot.empty) {
      console.log(`⚠️ User ${userUid} (${userEmail}) not found in database`);
      console.log(`🔐 === SYNC CLAIMS ON LOGIN END (USER NOT FOUND) ===`);
      throw new functions.https.HttpsError('not-found', 'User not found in database');
    }

    const userData = userSnapshot.docs[0].data();
    const userDocRef = userSnapshot.docs[0].ref;
    const userType = userData.userType;
    
    console.log(`🔐 Found user document: ${userSnapshot.docs[0].id}`);
    console.log(`🔐 User data: name=${userData.name}, userType=${userData.userType}`);

    if (!userType) {
      console.log('🔐 ❌ User type not found in document');
      throw new functions.https.HttpsError('invalid-argument', 'User type not found in database');
    }

    // Set custom claims
    console.log(`🔐 Setting custom claims: role=${userType}, university_path=${universityPath}`);
    await setUserClaims(userUid, {
      role: userType,
      university_path: universityPath
    });
    console.log('🔐 ✅ Custom claims set successfully');

    // Update user document with firebase_uid if missing
    if (!userData.firebase_uid) {
      await userDocRef.update({
        firebase_uid: userUid,
        last_login: new Date()
      });
      console.log(`📝 Updated user document with firebase_uid: ${userUid}`);
    } else {
      await userDocRef.update({
        last_login: new Date()
      });
    }

    console.log(`✅ Claims set for user ${userUid}: role=${userType}, university=${universityPath}`);
    console.log(`🔐 === SYNC CLAIMS ON LOGIN END (SUCCESS) ===`);

    return {
      success: true,
      message: 'Claims set successfully',
      claims: {
        role: userType,
        university_path: universityPath
      }
    };

  } catch (error) {
    console.error('🔐 ❌ Error syncing claims on login:', error);
    console.log(`🔐 === SYNC CLAIMS ON LOGIN END (ERROR) ===`);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to sync user claims');
  }
});

/**
 * HTTP function to set claims for newly registered users
 * This will be called by the frontend immediately after registration
 */
export const setClaimsOnRegistration = functions.https.onCall(async (data, context) => {
  try {
    console.log('🔐 === SET CLAIMS ON REGISTRATION START ===');
    console.log('🔐 Request data:', JSON.stringify(data));
    
    const { uid } = data;
    
    if (!uid) {
      console.log('🔐 ❌ No UID provided in request');
      throw new functions.https.HttpsError('invalid-argument', 'User UID is required');
    }
    
    console.log(`🔐 Setting claims for newly registered user: ${uid}`);
    
    // Get user record to verify they exist in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().getUser(uid);
      console.log(`🔐 Found Firebase Auth user: ${userRecord.email}`);
    } catch (authError) {
      console.log(`🔐 ❌ User not found in Firebase Auth: ${uid}`);
      throw new functions.https.HttpsError('not-found', 'User not found in Firebase Auth');
    }
    
    // Search for user in database to get their role
    const universityPath = 'california_merced_uc_merced'; // Default university for now
    console.log(`🔐 Searching in database path: ${universityPath}/data/users`);
    
    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Try to find user by firebase_uid
    console.log(`🔐 Step 1: Searching for user by firebase_uid: ${uid}`);
    let userSnapshot = await usersCollection
      .where('firebase_uid', '==', uid)
      .get();
    
    console.log(`🔐 Search by firebase_uid returned ${userSnapshot.size} documents`);
    
    // If not found by firebase_uid, try by email
    if (userSnapshot.empty && userRecord.email) {
      console.log(`🔐 Step 2: Not found by firebase_uid, trying email: ${userRecord.email}`);
      userSnapshot = await usersCollection
        .where('email', '==', userRecord.email)
        .get();
      console.log(`🔐 Search by email returned ${userSnapshot.size} documents`);
    }
    
    // If still not found, list all users for debugging
    if (userSnapshot.empty) {
      console.log(`🔐 ⚠️ User ${uid} (${userRecord.email}) not found in database`);
      console.log(`🔐 Listing first 10 users in database for debugging:`);
      
      const allUsersSnapshot = await usersCollection.limit(10).get();
      allUsersSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`🔐   ${index + 1}. ${doc.id}: name="${data.name}", email="${data.email}", firebase_uid="${data.firebase_uid || 'NOT SET'}"`);
      });
      
      console.log(`🔐 === SET CLAIMS ON REGISTRATION END (USER NOT FOUND) ===`);
      throw new functions.https.HttpsError('not-found', 'User not found in database. Please contact your coordinator.');
    }
    
    // User found - get their data
    const userData = userSnapshot.docs[0].data();
    const userDocRef = userSnapshot.docs[0].ref;
    const userType = userData.userType;
    
    console.log(`🔐 ✅ Found user document: ${userSnapshot.docs[0].id}`);
    console.log(`🔐 User data: name="${userData.name}", userType="${userData.userType}", email="${userData.email}"`);
    
    if (!userType) {
      console.log('🔐 ❌ User type not found in document');
      console.log('🔐 Full user data:', JSON.stringify(userData));
      throw new functions.https.HttpsError('invalid-argument', 'User type not found in database');
    }
    
    // Set custom claims
    console.log(`🔐 Setting custom claims: role="${userType}", university_path="${universityPath}"`);
    
    try {
      await setUserClaims(uid, {
        role: userType,
        university_path: universityPath
      });
      console.log('🔐 ✅ Custom claims set successfully via setUserClaims function');
    } catch (claimsError) {
      console.error('🔐 ❌ Error in setUserClaims function:', claimsError);
      throw new functions.https.HttpsError('internal', `Failed to set custom claims: ${claimsError}`);
    }
    
    // Verify claims were set by fetching user again
    const updatedUserRecord = await admin.auth().getUser(uid);
    console.log('🔐 Verification - Updated custom claims:', JSON.stringify(updatedUserRecord.customClaims || {}));
    
    // Update user document to confirm firebase_uid is set
    if (!userData.firebase_uid) {
      console.log(`🔐 Updating user document to add firebase_uid: ${uid}`);
      await userDocRef.update({
        firebase_uid: uid,
        account_created_at: new Date(),
        last_login: new Date()
      });
    }
    
    console.log(`🔐 ✅ SUCCESS: Claims set for user ${uid}: role="${userType}", university="${universityPath}"`);
    console.log(`🔐 === SET CLAIMS ON REGISTRATION END (SUCCESS) ===`);
    
    return {
      success: true,
      message: 'Claims set successfully for new user',
      claims: {
        role: userType,
        university_path: universityPath
      },
      debug: {
        uid: uid,
        email: userRecord.email,
        userName: userData.name,
        userType: userType,
        documentId: userSnapshot.docs[0].id
      }
    };
    
  } catch (error) {
    console.error('🔐 ❌ Error setting claims on registration:', error);
    
    // Type-safe error handling
    if (error instanceof Error) {
      console.error('🔐 Error type:', error.constructor.name);
      console.error('🔐 Error message:', error.message);
      console.error('🔐 Error stack:', error.stack);
    } else {
      console.error('🔐 Unknown error type:', typeof error);
      console.error('🔐 Error value:', error);
    }
    
    console.log(`🔐 === SET CLAIMS ON REGISTRATION END (ERROR) ===`);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    const errorMessage = error instanceof Error ? error.message : String(error);
    throw new functions.https.HttpsError('internal', `Failed to set user claims: ${errorMessage}`);
  }
});