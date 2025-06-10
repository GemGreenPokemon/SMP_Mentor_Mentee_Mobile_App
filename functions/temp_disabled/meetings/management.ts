import * as functions from 'firebase-functions';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument } from '../utils/database';
import { Meeting } from '../types';

interface CreateMeetingData {
  universityPath: string;
  mentor_id: string;
  mentee_id: string;
  start_time: string;
  end_time?: string;
  topic?: string;
  location?: string;
  availability_id?: string;
}

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
 * Create a new meeting
 */
export const createMeeting = functions.https.onCall(async (data: CreateMeetingData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, mentee_id, start_time, end_time, topic, location, availability_id } = data;
    
    // Validate input
    if (!mentor_id || !mentee_id || !start_time) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Verify user can create meeting (must be mentor, mentee, or coordinator)
    if (!['mentor', 'mentee', 'coordinator', 'super_admin'].includes(authContext.role || '')) {
      throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
    }

    // If user is mentor or mentee, they must be part of this meeting
    if (['mentor', 'mentee'].includes(authContext.role || '')) {
      if (authContext.uid !== mentor_id && authContext.uid !== mentee_id) {
        throw new functions.https.HttpsError('permission-denied', 'Can only create meetings you are part of');
      }
    }

    // Create meeting document
    const meeting: Omit<Meeting, 'id'> = {
      mentor_id,
      mentee_id,
      start_time,
      end_time,
      topic,
      location,
      status: 'pending',
      availability_id,
      created_at: new Date()
    };

    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const result = await createDocument(meetingsCollection, meeting);

    if (result.success) {
      console.log(`Meeting created: ${result.data?.id} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error creating meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to create meeting');
  }
});

/**
 * Update a meeting
 */
export const updateMeeting = functions.https.onCall(async (data: UpdateMeetingData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, ...updateData } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // TODO: Add permission check to verify user can update this specific meeting
    // This would require fetching the meeting first to check mentor_id/mentee_id

    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const result = await updateDocument(meetingsCollection, meetingId, {
      ...updateData,
      updated_at: new Date()
    });

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

/**
 * Cancel/Delete a meeting
 */
export const deleteMeeting = functions.https.onCall(async (data: { 
  universityPath: string; 
  meetingId: string;
  reason?: string;
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, reason } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // TODO: Add permission check to verify user can cancel this specific meeting

    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    
    // Instead of deleting, mark as cancelled for audit trail
    const result = await updateDocument(meetingsCollection, meetingId, {
      status: 'cancelled',
      cancellation_reason: reason,
      cancelled_by: authContext.uid,
      cancelled_at: new Date()
    });

    if (result.success) {
      console.log(`Meeting cancelled: ${meetingId} in ${universityPath} by ${authContext.uid}`);
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
 * Accept a meeting invitation
 */
export const acceptMeeting = functions.https.onCall(async (data: { 
  universityPath: string; 
  meetingId: string 
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const result = await updateDocument(meetingsCollection, meetingId, {
      status: 'accepted',
      accepted_by: authContext.uid,
      accepted_at: new Date()
    });

    if (result.success) {
      console.log(`Meeting accepted: ${meetingId} by ${authContext.uid}`);
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