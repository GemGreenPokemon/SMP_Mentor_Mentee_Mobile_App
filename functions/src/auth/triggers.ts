import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
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
        last_login: FieldValue.serverTimestamp()
      });
      console.log(`📝 Updated user document with firebase_uid: ${userUid}`);
    } else {
      await userDocRef.update({
        last_login: FieldValue.serverTimestamp()
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
  const startTime = Date.now();
  
  try {
    console.log('🔐 === SET CLAIMS ON REGISTRATION START ===');
    console.log(`🔐 Timestamp: ${new Date().toISOString()}`);
    console.log('🔐 Request data:', JSON.stringify(data));
    
    const { uid } = data;
    
    if (!uid) {
      console.log('🔐 ❌ No UID provided in request');
      throw new functions.https.HttpsError('invalid-argument', 'User UID is required. Please provide the Firebase Authentication UID.');
    }
    
    console.log(`🔐 Setting claims for newly registered user: ${uid}`);
    
    // Get user record to verify they exist in Firebase Auth
    let userRecord;
    const authStartTime = Date.now();
    try {
      userRecord = await admin.auth().getUser(uid);
      console.log(`🔐 ✅ Found Firebase Auth user: ${userRecord.email} (took ${Date.now() - authStartTime}ms)`);
      console.log(`🔐 Auth user details: emailVerified=${userRecord.emailVerified}, disabled=${userRecord.disabled}, created=${userRecord.metadata.creationTime}`);
    } catch (authError) {
      console.log(`🔐 ❌ User not found in Firebase Auth: ${uid} (took ${Date.now() - authStartTime}ms)`);
      console.error('🔐 Auth error details:', authError);
      throw new functions.https.HttpsError('not-found', `User with UID '${uid}' not found in Firebase Authentication. Please ensure the user has completed the authentication process.`);
    }
    
    // Search for user in database to get their role
    const universityPath = 'california_merced_uc_merced'; // Default university for now
    console.log(`🔐 Searching in database path: universities/${universityPath}/data/users`);
    
    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Try to find user by firebase_uid
    console.log(`🔐 Step 1: Searching for user by firebase_uid`);
    console.log(`🔐 Query: where('firebase_uid', '==', '${uid}')`);
    const queryStartTime = Date.now();
    
    let userSnapshot = await usersCollection
      .where('firebase_uid', '==', uid)
      .get();
    
    console.log(`🔐 Search by firebase_uid completed in ${Date.now() - queryStartTime}ms`);
    console.log(`🔐 Results: ${userSnapshot.size} document(s) found`);
    
    // If not found by firebase_uid, try by email
    if (userSnapshot.empty && userRecord.email) {
      console.log(`🔐 Step 2: Not found by firebase_uid, trying email search`);
      console.log(`🔐 Query: where('email', '==', '${userRecord.email}')`);
      const emailQueryStartTime = Date.now();
      
      userSnapshot = await usersCollection
        .where('email', '==', userRecord.email)
        .get();
        
      console.log(`🔐 Search by email completed in ${Date.now() - emailQueryStartTime}ms`);
      console.log(`🔐 Results: ${userSnapshot.size} document(s) found`);
    }
    
    // If still not found, list available users for debugging
    if (userSnapshot.empty) {
      console.log(`🔐 ⚠️ User ${uid} (${userRecord.email}) not found in database`);
      console.log(`🔐 Attempting to list available users for debugging purposes...`);
      
      const debugStartTime = Date.now();
      const allUsersSnapshot = await usersCollection.limit(5).get();
      console.log(`🔐 Debug query completed in ${Date.now() - debugStartTime}ms`);
      console.log(`🔐 Total users in collection (first 5):`);
      
      if (allUsersSnapshot.empty) {
        console.log(`🔐   ❌ No users found in the database at all!`);
        console.log(`🔐   This might indicate:`);
        console.log(`🔐   - The database has not been initialized`);
        console.log(`🔐   - The university path '${universityPath}' is incorrect`);
        console.log(`🔐   - Permission issues preventing read access`);
      } else {
        allUsersSnapshot.docs.forEach((doc, index) => {
          const data = doc.data();
          console.log(`🔐   ${index + 1}. Document ID: ${doc.id}`);
          console.log(`🔐      - name: "${data.name || 'N/A'}"`);
          console.log(`🔐      - email: "${data.email || 'N/A'}"`);
          console.log(`🔐      - firebase_uid: "${data.firebase_uid || 'NOT SET'}"`);
          console.log(`🔐      - userType: "${data.userType || 'N/A'}"`);
        });
      }
      
      console.log(`🔐 === SET CLAIMS ON REGISTRATION END (USER NOT FOUND) ===`);
      console.log(`🔐 Total execution time: ${Date.now() - startTime}ms`);
      
      throw new functions.https.HttpsError(
        'not-found', 
        `User account not found in the database. This usually means:\n` +
        `1. Your coordinator hasn't added you to the system yet\n` +
        `2. There's a mismatch between your registration email (${userRecord.email}) and the email in the database\n` +
        `Please contact your coordinator to ensure you've been added to the mentorship program.`
      );
    }
    
    // User found - get their data
    const userData = userSnapshot.docs[0].data();
    const userDocRef = userSnapshot.docs[0].ref;
    const userType = userData.userType;
    
    console.log(`🔐 ✅ Found user document: ${userSnapshot.docs[0].id}`);
    console.log(`🔐 User data:`);
    console.log(`🔐   - name: "${userData.name}"`);
    console.log(`🔐   - userType: "${userData.userType}"`);
    console.log(`🔐   - email: "${userData.email}"`);
    console.log(`🔐   - firebase_uid: "${userData.firebase_uid || 'NOT SET'}"`);
    
    if (!userType) {
      console.log('🔐 ❌ User type not found in document');
      console.log('🔐 Full user data:', JSON.stringify(userData, null, 2));
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'User role/type not found in database. Please contact your coordinator to ensure your account is properly configured.'
      );
    }
    
    // Set custom claims
    console.log(`🔐 Setting custom claims:`);
    console.log(`🔐   - role: "${userType}"`);
    console.log(`🔐   - university_path: "${universityPath}"`);
    
    const claimsStartTime = Date.now();
    try {
      await setUserClaims(uid, {
        role: userType,
        university_path: universityPath
      });
      console.log(`🔐 ✅ Custom claims set successfully via setUserClaims function (took ${Date.now() - claimsStartTime}ms)`);
    } catch (claimsError) {
      console.error('🔐 ❌ Error in setUserClaims function:', claimsError);
      console.error('🔐 Claims error type:', claimsError instanceof Error ? claimsError.constructor.name : typeof claimsError);
      console.error('🔐 Claims error message:', claimsError instanceof Error ? claimsError.message : String(claimsError));
      
      throw new functions.https.HttpsError(
        'internal', 
        `Failed to set custom claims. This is an internal error. Please try again or contact support if the issue persists. Error: ${claimsError instanceof Error ? claimsError.message : String(claimsError)}`
      );
    }
    
    // Verify claims were set by fetching user again
    const verifyStartTime = Date.now();
    const updatedUserRecord = await admin.auth().getUser(uid);
    console.log(`🔐 Verification completed in ${Date.now() - verifyStartTime}ms`);
    console.log('🔐 Verification - Updated custom claims:', JSON.stringify(updatedUserRecord.customClaims || {}));
    
    // Update user document to confirm firebase_uid is set
    if (!userData.firebase_uid) {
      console.log(`🔐 Updating user document to add firebase_uid: ${uid}`);
      const updateStartTime = Date.now();
      
      await userDocRef.update({
        firebase_uid: uid,
        account_created_at: FieldValue.serverTimestamp(),
        last_login: FieldValue.serverTimestamp()
      });
      
      console.log(`🔐 ✅ User document updated (took ${Date.now() - updateStartTime}ms)`);
    } else {
      // Just update last_login
      const updateStartTime = Date.now();
      await userDocRef.update({
        last_login: FieldValue.serverTimestamp()
      });
      console.log(`🔐 ✅ Last login updated (took ${Date.now() - updateStartTime}ms)`);
    }
    
    const totalTime = Date.now() - startTime;
    console.log(`🔐 ✅ SUCCESS: Claims set for user ${uid}`);
    console.log(`🔐   - role: "${userType}"`);
    console.log(`🔐   - university: "${universityPath}"`);
    console.log(`🔐   - total execution time: ${totalTime}ms`);
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
        documentId: userSnapshot.docs[0].id,
        executionTimeMs: totalTime
      }
    };
    
  } catch (error) {
    const totalTime = Date.now() - startTime;
    console.error('🔐 ❌ Error setting claims on registration:', error);
    console.error(`🔐 Error occurred after ${totalTime}ms`);
    
    // Type-safe error handling
    if (error instanceof Error) {
      console.error('🔐 Error type:', error.constructor.name);
      console.error('🔐 Error message:', error.message);
      console.error('🔐 Error stack:', error.stack);
    } else {
      console.error('🔐 Unknown error type:', typeof error);
      console.error('🔐 Error value:', JSON.stringify(error));
    }
    
    console.log(`🔐 === SET CLAIMS ON REGISTRATION END (ERROR) ===`);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    const errorMessage = error instanceof Error ? error.message : String(error);
    throw new functions.https.HttpsError(
      'internal', 
      `An unexpected error occurred while setting up your account. Please try again or contact support if the issue persists. Error: ${errorMessage}`
    );
  }
});