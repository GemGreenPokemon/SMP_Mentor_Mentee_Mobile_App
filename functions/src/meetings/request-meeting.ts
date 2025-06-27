import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection } from '../utils/database';
import { getUserDocByUid, generateMeetingId } from './utils/meeting-helpers';

interface RequestMeetingData {
  universityPath: string;
  mentor_id: string;
  mentee_id: string;
  date: string;
  start_time: string;
  end_time?: string;
  topic: string;
  location?: string;
  availability_id?: string;
}

/**
 * Request a meeting (typically used by mentees)
 * Creates a meeting with 'pending' status in top-level collection
 */
export const requestMeeting = functions.https.onCall(async (data: RequestMeetingData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, mentee_id, date, start_time, end_time, topic, location, availability_id } = data;
    
    // Validate input
    if (!mentor_id || !mentee_id || !date || !start_time || !topic) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Verify user is authenticated
    if (!authContext.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // If user is a mentee, they can only request meetings for themselves
    if (authContext.role === 'mentee' && authContext.uid !== mentee_id) {
      throw new functions.https.HttpsError('permission-denied', 'Can only request meetings for yourself');
    }

    // Combine date and time
    const startDateTime = `${date}T${start_time}`;
    const endDateTime = end_time ? `${date}T${end_time}` : null;

    // Get user documents for both mentor and mentee
    const [mentorDoc, menteeDoc] = await Promise.all([
      getUserDocByUid(universityPath, mentor_id),
      getUserDocByUid(universityPath, mentee_id)
    ]);

    if (!mentorDoc || !menteeDoc) {
      throw new functions.https.HttpsError('not-found', 'Mentor or mentee not found');
    }

    console.log(`Creating meeting request from mentee ${menteeDoc.id} to mentor ${mentorDoc.id}`);

    // If availability_id is provided, check if it's available
    if (availability_id) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      const slotDoc = await availabilityCollection.doc(availability_id).get();
      
      if (!slotDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Availability slot not found');
      }
      
      const slotData = slotDoc.data()!;
      
      if (slotData.is_booked) {
        throw new functions.https.HttpsError('failed-precondition', 'This slot is already booked');
      }
      
      if (slotData.mentor_uid !== mentor_id) {
        throw new functions.https.HttpsError('invalid-argument', 'Availability slot does not belong to the specified mentor');
      }
    }

    // Generate human-readable meeting ID
    const meetingId = generateMeetingId(mentorDoc.id, menteeDoc.id, startDateTime);

    // Create meeting document
    const meeting = {
      id: meetingId,
      // Document IDs for the meeting ID and querying
      mentor_doc_id: mentorDoc.id,
      mentee_doc_id: menteeDoc.id,
      // Firebase UIDs for authentication and queries
      mentor_uid: mentor_id,
      mentee_uid: mentee_id,
      // Denormalized names for display
      mentor_name: mentorDoc.data.name || '',
      mentee_name: menteeDoc.data.name || '',
      // Meeting details
      start_time: admin.firestore.Timestamp.fromDate(new Date(startDateTime)),
      end_time: endDateTime ? admin.firestore.Timestamp.fromDate(new Date(endDateTime)) : null,
      topic: topic,
      location: location || '',
      status: 'pending',
      availability_id: availability_id || null,
      // Metadata
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      created_by: authContext.uid,
      requested_by: mentee_id,
      requested_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };

    // Create meeting in top-level collection
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    await meetingsCollection.doc(meetingId).set(meeting);

    // Note: We don't book the availability slot yet - it will be booked when the mentor accepts
    
    console.log(`Meeting request created successfully: ${meetingId}`);

    return {
      success: true,
      data: {
        ...meeting,
        // Override with meeting interface compatible values
        id: meetingId,
        mentor_id: mentor_id,
        mentee_id: mentee_id,
        start_time: startDateTime,
        end_time: endDateTime || undefined,
        status: 'pending' as const,
        availability_id: availability_id || undefined,
        created_at: new Date(),
        // Additional fields for response
        mentor_doc_id: mentorDoc.id,
        mentee_doc_id: menteeDoc.id,
        requested_at: new Date().toISOString()
      }
    };

  } catch (error) {
    console.error('Error requesting meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to request meeting');
  }
});