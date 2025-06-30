import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection } from '../utils/database';
import { Meeting } from '../types';
import { getUserDocByUid, generateMeetingId } from './utils/meeting-helpers';

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

/**
 * Create a new meeting in the top-level meetings collection
 * No longer writes to user subcollections
 */
export const createMeeting = functions.https.onCall(async (data: CreateMeetingData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, mentee_id, start_time, end_time, topic, location, availability_id } = data;
    
    // Debug logging for timezone issue
    console.log('DEBUG: Create meeting request:');
    console.log('  - start_time string:', start_time);
    console.log('  - start_time parsed:', new Date(start_time));
    console.log('  - start_time UTC:', new Date(start_time).toUTCString());
    console.log('  - start_time ISO:', new Date(start_time).toISOString());
    
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

    // Get user documents for both mentor and mentee
    const [mentorDoc, menteeDoc] = await Promise.all([
      getUserDocByUid(universityPath, mentor_id),
      getUserDocByUid(universityPath, mentee_id)
    ]);

    if (!mentorDoc || !menteeDoc) {
      throw new functions.https.HttpsError('not-found', 'Mentor or mentee not found');
    }

    console.log(`Creating meeting between mentor ${mentorDoc.id} and mentee ${menteeDoc.id}`);
    console.log('Input data:', { start_time, end_time, topic, location, availability_id });
    console.log('Admin check:', {
      hasAdmin: !!admin,
      hasFirestore: !!admin.firestore,
      hasTimestamp: !!admin.firestore?.Timestamp,
      hasFromDate: !!admin.firestore?.Timestamp?.fromDate
    });

    // Generate human-readable meeting ID
    const meetingId = generateMeetingId(mentorDoc.id, menteeDoc.id, start_time);

    // Create meeting document with new structure
    const meetingData = {
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
      // Meeting details - store as Timestamps in Firestore
      // Parse the ISO string properly to maintain timezone
      start_time: Timestamp.fromDate(new Date(start_time)),
      end_time: end_time ? Timestamp.fromDate(new Date(end_time)) : null,
      topic: topic || '',
      location: location || '',
      status: 'pending',
      availability_id: availability_id || null,
      // Metadata
      created_at: FieldValue.serverTimestamp(),
      created_by: authContext.uid,
      updated_at: FieldValue.serverTimestamp(),
      // For type compatibility with Meeting interface
      mentor_id: mentor_id,
      mentee_id: mentee_id
    };

    // Create meeting in top-level collection only
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    await meetingsCollection.doc(meetingId).set(meetingData);

    // If availability_id is provided, mark the slot as booked
    if (availability_id) {
      try {
        const availabilityCollection = getUniversityCollection(universityPath, 'availability');
        
        // For new structure, availability_id is the document ID
        await availabilityCollection.doc(availability_id).update({
          is_booked: true,
          booked_by_uid: mentee_id,
          booked_by_doc_id: menteeDoc.id,
          booked_by_name: menteeDoc.data.name || '',
          meeting_id: meetingId,
          booked_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp()
        });

        console.log(`Marked availability slot ${availability_id} as booked for meeting ${meetingId}`);
      } catch (error) {
        console.error(`Failed to mark availability slot as booked: ${error}`);
        // Don't fail the meeting creation if availability update fails
      }
    }

    console.log(`Meeting created successfully: ${meetingId} in ${universityPath}`);

    return {
      success: true,
      data: {
        ...meetingData,
        // Override with meeting interface compatible values
        id: meetingId,
        mentor_id: mentor_id,
        mentee_id: mentee_id,
        start_time: start_time,
        end_time: end_time || undefined,
        status: 'pending' as const,
        availability_id: availability_id || undefined,
        created_at: new Date(),
        // Additional fields for response
        mentor_doc_id: mentorDoc.id,
        mentee_doc_id: menteeDoc.id
      }
    };

  } catch (error) {
    console.error('Error creating meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to create meeting');
  }
});