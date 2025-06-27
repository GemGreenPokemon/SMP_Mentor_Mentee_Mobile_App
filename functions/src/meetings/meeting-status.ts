import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, getDocument, updateDocument } from '../utils/database';
import { Meeting } from '../types';

interface StatusUpdateData {
  universityPath: string;
  meetingId: string;
  reason?: string;
}

/**
 * Cancel/Delete a meeting
 * Updates meeting status in top-level collection only
 */
export const cancelMeeting = functions.https.onCall(async (data: StatusUpdateData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, reason } = data;
    
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
      const userUid = authContext.uid;
      if (userUid !== meeting.mentor_id && userUid !== meeting.mentee_id &&
          userUid !== meeting.mentor_uid && userUid !== meeting.mentee_uid) {
        throw new functions.https.HttpsError('permission-denied', 'Can only cancel meetings you are part of');
      }
    }

    const updates = {
      status: 'cancelled',
      cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
      cancelled_by: authContext.uid,
      cancellation_reason: reason || null,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: authContext.uid
    };

    const result = await updateDocument(meetingsCollection, meetingId, updates);

    // If meeting had an availability slot, unbook it
    if (meeting.availability_id) {
      try {
        const availabilityCollection = getUniversityCollection(universityPath, 'availability');
        await availabilityCollection.doc(meeting.availability_id).update({
          is_booked: false,
          booked_by_uid: null,
          booked_by_doc_id: null,
          booked_by_name: null,
          meeting_id: null,
          booked_at: null,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Unbooked availability slot ${meeting.availability_id}`);
      } catch (error) {
        console.error(`Failed to unbook availability slot: ${error}`);
      }
    }

    if (result.success) {
      console.log(`Meeting cancelled: ${meetingId} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error cancelling meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to cancel meeting');
  }
});

/**
 * Accept a meeting request (mentor only)
 * Updates meeting status in top-level collection only
 */
export const acceptMeeting = functions.https.onCall(async (data: StatusUpdateData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // Get the meeting
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const meetingDoc = await getDocument(meetingsCollection, meetingId);
    
    if (!meetingDoc.success || !meetingDoc.data) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    const meeting = meetingDoc.data as Meeting & { mentor_uid?: string };
    
    // Check permissions - only mentor can accept
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      const userUid = authContext.uid;
      if (userUid !== meeting.mentor_id && userUid !== meeting.mentor_uid) {
        throw new functions.https.HttpsError('permission-denied', 'Only the mentor can accept this meeting');
      }
    }

    // Check current status
    if (meeting.status !== 'pending') {
      throw new functions.https.HttpsError('failed-precondition', `Cannot accept meeting with status: ${meeting.status}`);
    }

    const updates = {
      status: 'accepted',
      accepted_at: admin.firestore.FieldValue.serverTimestamp(),
      accepted_by: authContext.uid,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: authContext.uid
    };

    const result = await updateDocument(meetingsCollection, meetingId, updates);

    if (result.success) {
      console.log(`Meeting accepted: ${meetingId} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error accepting meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to accept meeting');
  }
});

/**
 * Reject a meeting request (mentor only)
 * Updates meeting status in top-level collection only
 */
export const rejectMeeting = functions.https.onCall(async (data: StatusUpdateData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, reason } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // Get the meeting
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const meetingDoc = await getDocument(meetingsCollection, meetingId);
    
    if (!meetingDoc.success || !meetingDoc.data) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    const meeting = meetingDoc.data as Meeting & { mentor_uid?: string };
    
    // Check permissions - only mentor can reject
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      const userUid = authContext.uid;
      if (userUid !== meeting.mentor_id && userUid !== meeting.mentor_uid) {
        throw new functions.https.HttpsError('permission-denied', 'Only the mentor can reject this meeting');
      }
    }

    // Check current status
    if (meeting.status !== 'pending') {
      throw new functions.https.HttpsError('failed-precondition', `Cannot reject meeting with status: ${meeting.status}`);
    }

    const updates = {
      status: 'rejected',
      rejected_at: admin.firestore.FieldValue.serverTimestamp(),
      rejected_by: authContext.uid,
      rejection_reason: reason || null,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: authContext.uid
    };

    const result = await updateDocument(meetingsCollection, meetingId, updates);

    // If meeting had an availability slot, unbook it
    if (meeting.availability_id) {
      try {
        const availabilityCollection = getUniversityCollection(universityPath, 'availability');
        await availabilityCollection.doc(meeting.availability_id).update({
          is_booked: false,
          booked_by_uid: null,
          booked_by_doc_id: null,
          booked_by_name: null,
          meeting_id: null,
          booked_at: null,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Unbooked availability slot ${meeting.availability_id}`);
      } catch (error) {
        console.error(`Failed to unbook availability slot: ${error}`);
      }
    }

    if (result.success) {
      console.log(`Meeting rejected: ${meetingId} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error rejecting meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to reject meeting');
  }
});