import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, getDocument, updateDocument } from '../utils/database';
import { Meeting } from '../types';

interface UpdateMeetingData {
  universityPath: string;
  meetingId: string;
  start_time?: string;
  end_time?: string;
  topic?: string;
  location?: string;
  status?: 'pending' | 'accepted' | 'rejected' | 'cancelled';
}

/**
 * Update a meeting in the top-level meetings collection
 * No longer updates user subcollections
 */
export const updateMeeting = functions.https.onCall(async (data: UpdateMeetingData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, ...updateData } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // Get the meeting to check permissions
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const meetingDoc = await getDocument(meetingsCollection, meetingId);
    
    if (!meetingDoc.success || !meetingDoc.data) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    const meeting = meetingDoc.data as Meeting & { mentor_uid?: string; mentee_uid?: string };
    
    // Check permissions
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      // Check if user is part of the meeting
      const userUid = authContext.uid;
      if (userUid !== meeting.mentor_id && userUid !== meeting.mentee_id &&
          userUid !== meeting.mentor_uid && userUid !== meeting.mentee_uid) {
        throw new functions.https.HttpsError('permission-denied', 'Can only update meetings you are part of');
      }
    }

    // Prepare update data
    const updates: any = {
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: authContext.uid
    };

    // Add provided fields to update
    if (updateData.start_time) {
      updates.start_time = admin.firestore.Timestamp.fromDate(new Date(updateData.start_time));
    }
    if (updateData.end_time) {
      updates.end_time = admin.firestore.Timestamp.fromDate(new Date(updateData.end_time));
    }
    if (updateData.topic !== undefined) {
      updates.topic = updateData.topic;
    }
    if (updateData.location !== undefined) {
      updates.location = updateData.location;
    }
    if (updateData.status) {
      updates.status = updateData.status;
    }

    // Update meeting in top-level collection only
    const result = await updateDocument(meetingsCollection, meetingId, updates);

    if (result.success) {
      console.log(`Meeting updated: ${meetingId} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error updating meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to update meeting');
  }
});