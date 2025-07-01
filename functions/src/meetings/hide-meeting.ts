import * as functions from 'firebase-functions';
import { CallableContext } from 'firebase-functions/v1/https';
import { FieldValue } from 'firebase-admin/firestore';
import { verifyAuth } from '../utils/auth';
import { getDB } from '../utils/database';

interface HideMeetingData {
  universityPath: string;
  meetingId: string;
}

/**
 * Hide a meeting from the user's view
 * This doesn't delete the meeting, just marks it as hidden for the current user
 */
export const hideMeeting = functions.https.onCall(async (data: HideMeetingData, context: CallableContext) => {
  console.log('🔍 hideMeeting: Function called with data:', JSON.stringify(data));
  try {
    // Authenticate user
    console.log('🔍 hideMeeting: Authenticating user...');
    const authContext = await verifyAuth(context);
    console.log('🔍 hideMeeting: User authenticated:', authContext.uid);
    
    const { universityPath, meetingId } = data;
    console.log('🔍 hideMeeting: universityPath:', universityPath);
    console.log('🔍 hideMeeting: meetingId:', meetingId);
    
    if (!meetingId) {
      console.log('🔍 hideMeeting: Error - Meeting ID is missing');
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID is required');
    }
    
    // Get database instance
    console.log('🔍 hideMeeting: Getting database instance...');
    const db = getDB();
    
    // Get meeting reference
    const meetingPath = `${universityPath}/data/meetings/${meetingId}`;
    console.log('🔍 hideMeeting: Meeting path:', meetingPath);
    const meetingRef = db.doc(meetingPath);
    const meetingDoc = await meetingRef.get();
    
    if (!meetingDoc.exists) {
      console.log('🔍 hideMeeting: Error - Meeting not found at path:', meetingPath);
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    console.log('🔍 hideMeeting: Meeting found');
    const meeting = meetingDoc.data()!;
    console.log('🔍 hideMeeting: Meeting data:', JSON.stringify({
      id: meetingDoc.id,
      status: meeting.status,
      mentor_id: meeting.mentor_id,
      mentee_id: meeting.mentee_id,
      mentor_uid: meeting.mentor_uid,
      mentee_uid: meeting.mentee_uid,
      hidden_by: meeting.hidden_by
    }));
    
    // Check permissions - user must be part of the meeting
    console.log('🔍 hideMeeting: Checking permissions...');
    console.log('🔍 hideMeeting: User role:', authContext.role);
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      const userUid = authContext.uid;
      console.log('🔍 hideMeeting: Checking if user is part of meeting...');
      if (userUid !== meeting.mentor_id && userUid !== meeting.mentee_id &&
          userUid !== meeting.mentor_uid && userUid !== meeting.mentee_uid) {
        console.log('🔍 hideMeeting: Error - User not part of meeting');
        throw new functions.https.HttpsError('permission-denied', 'Can only hide meetings you are part of');
      }
    }
    
    console.log('🔍 hideMeeting: Permission check passed');
    
    // Add the user to the hidden_by array
    console.log('🔍 hideMeeting: Adding user to hidden_by array...');
    await meetingRef.update({
      hidden_by: FieldValue.arrayUnion(authContext.uid),
      updated_at: FieldValue.serverTimestamp(),
    });
    
    console.log(`🔍 hideMeeting: Meeting ${meetingId} successfully hidden for user ${authContext.uid}`);
    
    return { 
      success: true, 
      message: 'Meeting hidden successfully',
      meetingId 
    };
  } catch (error: any) {
    console.error('Error hiding meeting:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', `Failed to hide meeting: ${error.message}`);
  }
});

/**
 * Unhide a meeting for the user
 */
export const unhideMeeting = functions.https.onCall(async (data: HideMeetingData, context: CallableContext) => {
  try {
    // Authenticate user
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID is required');
    }
    
    // Get database instance
    const db = getDB();
    
    // Get meeting reference
    const meetingRef = db.doc(`${universityPath}/data/meetings/${meetingId}`);
    const meetingDoc = await meetingRef.get();
    
    if (!meetingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    // Remove the user from the hidden_by array
    await meetingRef.update({
      hidden_by: FieldValue.arrayRemove(authContext.uid),
      updated_at: FieldValue.serverTimestamp(),
    });
    
    console.log(`Meeting ${meetingId} unhidden for user ${authContext.uid}`);
    
    return { 
      success: true, 
      message: 'Meeting unhidden successfully',
      meetingId 
    };
  } catch (error: any) {
    console.error('Error unhiding meeting:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', `Failed to unhide meeting: ${error.message}`);
  }
});