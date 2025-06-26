import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

/**
 * Check if a mentee has completed their acknowledgment
 * This is a secure way to check acknowledgment status without exposing the entire user collection
 */
export const checkMenteeAcknowledgment = functions.https.onCall(async (data, context) => {
  console.log('=== checkMenteeAcknowledgment START ===');
  console.log('Context auth:', context.auth ? 'Present' : 'Missing');
  
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to check acknowledgment status'
    );
  }

  const userId = context.auth.uid;
  const userEmail = context.auth.token.email;
  
  console.log(`User details: uid=${userId}, email=${userEmail}`);
  console.log('Full token claims:', JSON.stringify(context.auth.token));
  
  // Check custom claims first - this confirms role was set successfully
  const userRole = context.auth.token.role || context.auth.token.userType;
  console.log(`Checking acknowledgment for user ${userId} with role from claims: ${userRole}`);
  
  // If not a mentee based on custom claims, no acknowledgment needed
  if (userRole !== 'mentee') {
    console.log('User is not a mentee, returning needsAcknowledgment: false');
    return {
      success: true,
      needsAcknowledgment: false,
      message: 'User is not a mentee (verified by custom claims)'
    };
  }

  try {
    // User is confirmed as mentee via custom claims, now check acknowledgment status
    const universityPath = 'california_merced_uc_merced';
    
    // First try to find user by firebase_uid
    let userSnapshot = await admin.firestore()
      .collection(universityPath)
      .doc('data')
      .collection('users')
      .where('firebase_uid', '==', userId)
      .limit(1)
      .get();

    // If not found by UID, try by email
    if (userSnapshot.empty && userEmail) {
      userSnapshot = await admin.firestore()
        .collection(universityPath)
        .doc('data')
        .collection('users')
        .where('email', '==', userEmail)
        .limit(1)
        .get();
    }

    if (userSnapshot.empty) {
      console.log(`No user document found for uid: ${userId}, email: ${userEmail}`);
      // Since custom claims confirm they're a mentee, they need acknowledgment
      return {
        success: true,
        needsAcknowledgment: true,
        message: 'User document not found but confirmed as mentee via claims'
      };
    }

    const userData = userSnapshot.docs[0].data();
    console.log('User document found:', userSnapshot.docs[0].id);
    console.log('User data:', JSON.stringify(userData));

    // Check acknowledgment status - only check the acknowledgment_signed field
    const acknowledgmentSigned = userData.acknowledgment_signed || 'no';
    
    // Mentee needs acknowledgment if not signed
    const needsAcknowledgment = acknowledgmentSigned !== 'yes';

    console.log(`User ${userEmail} acknowledgment_signed: "${acknowledgmentSigned}", needs acknowledgment: ${needsAcknowledgment}`);
    console.log(`Comparison: "${acknowledgmentSigned}" !== "yes" = ${acknowledgmentSigned !== 'yes'}`);
    
    const response = {
      success: true,
      needsAcknowledgment: needsAcknowledgment,
      acknowledgmentStatus: {
        signed: acknowledgmentSigned
      }
    };
    
    console.log('=== checkMenteeAcknowledgment RESPONSE ===');
    console.log(JSON.stringify(response));
    
    return response;

  } catch (error) {
    console.error('Error checking mentee acknowledgment:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to check acknowledgment status',
      error
    );
  }
});

/**
 * Submit mentee acknowledgment
 * Securely updates the user's acknowledgment status
 */
export const submitMenteeAcknowledgment = functions.https.onCall(async (data, context) => {
  console.log('=== submitMenteeAcknowledgment START ===');
  console.log('📝 Received data:', JSON.stringify(data));
  console.log('📝 Context auth present:', !!context.auth);
  
  // Check if user is authenticated
  if (!context.auth) {
    console.error('❌ No authentication context found');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to submit acknowledgment'
    );
  }

  const userId = context.auth.uid;
  const userEmail = context.auth.token.email;
  const { fullName } = data;
  
  console.log(`📝 User ${userId} (${userEmail}) submitting acknowledgment`);
  console.log(`📝 Full name provided: "${fullName}"`);
  
  // NOTE: We don't check custom claims here because mentees won't have them yet
  // They get custom claims AFTER signing the acknowledgment

  // Validate input
  if (!fullName || typeof fullName !== 'string' || fullName.trim().length < 3) {
    console.error('❌ Invalid full name:', fullName);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Valid full name is required'
    );
  }

  try {
    const universityPath = 'california_merced_uc_merced';
    console.log(`📝 Using university path: ${universityPath}`);
    
    // First try to find user by firebase_uid
    console.log(`📝 Searching for user by firebase_uid: ${userId}`);
    console.log(`📝 Full path: ${universityPath}/data/users where firebase_uid == ${userId}`);
    
    let userSnapshot = await admin.firestore()
      .collection(universityPath)
      .doc('data')
      .collection('users')
      .where('firebase_uid', '==', userId)
      .limit(1)
      .get();
    
    console.log(`📝 Search by firebase_uid returned ${userSnapshot.size} documents`);

    // If not found by UID, try by email
    if (userSnapshot.empty && userEmail) {
      console.log(`📝 No user found by UID, trying email: ${userEmail}`);
      userSnapshot = await admin.firestore()
        .collection(universityPath)
        .doc('data')
        .collection('users')
        .where('email', '==', userEmail)
        .limit(1)
        .get();
      console.log(`📝 Search by email returned ${userSnapshot.size} documents`);
    }

    if (userSnapshot.empty) {
      console.error(`❌ No user document found for UID: ${userId} or email: ${userEmail}`);
      throw new functions.https.HttpsError(
        'not-found',
        'User document not found'
      );
    }

    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data();
    console.log(`📝 Found user document: ${userDoc.id}`);
    console.log(`📝 Current user data:`, JSON.stringify(userData));

    // Update user document with acknowledgment - simply change "no" to "yes"
    console.log(`📝 Attempting to update document at path: ${userDoc.ref.path}`);
    console.log(`📝 Update data: acknowledgment_signed="yes", fullName="${fullName.trim()}"`);
    
    try {
      await userDoc.ref.update({
        acknowledgment_signed: 'yes',
        acknowledgmentDate: FieldValue.serverTimestamp(),
        acknowledgmentFullName: fullName.trim()
      });
      console.log(`✅ Successfully updated acknowledgment_signed to "yes" for user ${userDoc.id}`);
    } catch (updateError) {
      console.error('❌ Error updating user document:', updateError);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update acknowledgment status',
        updateError
      );
    }

    // Now set custom claims for the mentee after successful acknowledgment
    console.log('Setting custom claims for mentee after acknowledgment...');
    try {
      const customClaims = {
        role: 'mentee',
        university_path: universityPath
      };
      
      await admin.auth().setCustomUserClaims(userId, customClaims);
      console.log(`Custom claims set successfully for mentee ${userId}:`, customClaims);
      
      // Return success with claims info
      return {
        success: true,
        message: 'Acknowledgment submitted and access granted successfully',
        claimsSet: true,
        claims: customClaims
      };
    } catch (claimsError) {
      console.error('Error setting custom claims after acknowledgment:', claimsError);
      // Still return success for acknowledgment, but note claims failed
      return {
        success: true,
        message: 'Acknowledgment submitted successfully (claims may need refresh)',
        claimsSet: false,
        claimsError: claimsError instanceof Error ? claimsError.message : String(claimsError)
      };
    }

  } catch (error) {
    console.error('❌ Error in submitMenteeAcknowledgment:', error);
    console.error('❌ Error type:', typeof error);
    console.error('❌ Error details:', JSON.stringify(error, null, 2));
    
    if (error instanceof functions.https.HttpsError) {
      console.error('❌ Rethrowing HttpsError:', error.message);
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to submit acknowledgment: ' + (error instanceof Error ? error.message : String(error)),
      error
    );
  } finally {
    console.log('=== submitMenteeAcknowledgment END ===');
  }
});