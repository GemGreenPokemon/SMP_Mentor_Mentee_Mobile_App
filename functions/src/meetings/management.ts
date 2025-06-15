import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument, getDocument } from '../utils/database';
import { Meeting } from '../types';

// ========== TYPES ==========
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

interface Availability {
  id?: string;
  mentor_id: string;
  day: string;
  slots: Array<{
    slot_start: string;
    slot_end?: string;
    is_booked: boolean;
    mentee_id?: string;
    meeting_id?: string;
  }>;
  created_at?: Date;
  updated_at?: Date;
}

interface SetAvailabilityData {
  universityPath: string;
  mentor_id: string;
  day: string;
  slots: Array<{
    slot_start: string;
    slot_end?: string;
  }>;
}

// ========== MEETING FUNCTIONS ==========

/**
 * Create a new meeting
 */
export const createMeeting = functions.https.onCall(async (data: CreateMeetingData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
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

    // If availability_id is provided, book the slot
    if (availability_id) {
      // Parse the availability_id to get document ID and slot index
      // Format: "docId_slot_0"
      const parts = availability_id.split('_slot_');
      const docId = parts[0];
      const slotIndex = parts[1] ? parseInt(parts[1]) : -1;
      
      if (slotIndex === -1) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid availability slot ID format');
      }
      
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      const availabilityDoc = await getDocument(availabilityCollection, docId);
      
      if (!availabilityDoc.success || !availabilityDoc.data) {
        throw new functions.https.HttpsError('not-found', 'Availability slot not found');
      }
      
      const availabilityData = availabilityDoc.data as Availability;
      
      // Check if the specific slot exists and is not booked
      if (!availabilityData.slots || !availabilityData.slots[slotIndex]) {
        throw new functions.https.HttpsError('not-found', 'Specific time slot not found');
      }
      
      if (availabilityData.slots[slotIndex].is_booked) {
        throw new functions.https.HttpsError('failed-precondition', 'This slot is already booked');
      }
      
      // TODO: Update the slot to mark it as booked
      // This would require updating the specific slot in the array
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

    // If availability_id is provided and meeting created successfully, mark slot as booked
    if (result.success && availability_id && result.data?.id) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      await updateDocument(availabilityCollection, availability_id, {
        is_booked: true,
        mentee_id,
        meeting_id: result.data.id,
        updated_at: new Date()
      });
    }

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
    
    const meeting = meetingDoc.data as Meeting;
    
    // Check permissions
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      if (authContext.uid !== meeting.mentor_id && authContext.uid !== meeting.mentee_id) {
        throw new functions.https.HttpsError('permission-denied', 'Can only update meetings you are part of');
      }
    }

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
export const cancelMeeting = functions.https.onCall(async (data: { 
  universityPath: string; 
  meetingId: string;
  reason?: string;
}, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId, reason } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // Get the meeting to check permissions and availability
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const meetingDoc = await getDocument(meetingsCollection, meetingId);
    
    if (!meetingDoc.success || !meetingDoc.data) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    const meeting = meetingDoc.data as Meeting;
    
    // Check permissions
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      if (authContext.uid !== meeting.mentor_id && authContext.uid !== meeting.mentee_id) {
        throw new functions.https.HttpsError('permission-denied', 'Can only cancel meetings you are part of');
      }
    }
    
    // Instead of deleting, mark as cancelled for audit trail
    const result = await updateDocument(meetingsCollection, meetingId, {
      status: 'cancelled',
      cancellation_reason: reason,
      cancelled_by: authContext.uid,
      cancelled_at: new Date()
    });

    // If meeting had an availability slot, free it up
    if (meeting.availability_id) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      await updateDocument(availabilityCollection, meeting.availability_id, {
        is_booked: false,
        mentee_id: null,
        meeting_id: null,
        updated_at: new Date()
      });
    }

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
    const authContext = await verifyAuth(context);
    
    const { universityPath, meetingId } = data;
    
    if (!meetingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Meeting ID required');
    }

    // Get the meeting to check permissions
    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const meetingDoc = await getDocument(meetingsCollection, meetingId);
    
    if (!meetingDoc.success || !meetingDoc.data) {
      throw new functions.https.HttpsError('not-found', 'Meeting not found');
    }
    
    const meeting = meetingDoc.data as Meeting;
    
    // Only the mentor can accept meeting requests
    if (authContext.uid !== meeting.mentor_id) {
      throw new functions.https.HttpsError('permission-denied', 'Only the mentor can accept meeting requests');
    }

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

/**
 * Reject a meeting invitation
 */
export const rejectMeeting = functions.https.onCall(async (data: { 
  universityPath: string; 
  meetingId: string;
  reason?: string;
}, context) => {
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
    
    const meeting = meetingDoc.data as Meeting;
    
    // Only the mentor can reject meeting requests
    if (authContext.uid !== meeting.mentor_id) {
      throw new functions.https.HttpsError('permission-denied', 'Only the mentor can reject meeting requests');
    }

    const result = await updateDocument(meetingsCollection, meetingId, {
      status: 'rejected',
      rejection_reason: reason,
      rejected_by: authContext.uid,
      rejected_at: new Date()
    });

    // If meeting had an availability slot, free it up
    if (meeting.availability_id) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      await updateDocument(availabilityCollection, meeting.availability_id, {
        is_booked: false,
        mentee_id: null,
        meeting_id: null,
        updated_at: new Date()
      });
    }

    if (result.success) {
      console.log(`Meeting rejected: ${meetingId} by ${authContext.uid}`);
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

// ========== AVAILABILITY FUNCTIONS ==========

/**
 * Set mentor availability for a specific day
 */
export const setMentorAvailability = functions.https.onCall(async (data: SetAvailabilityData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, day, slots } = data;
    
    // Validate input
    if (!mentor_id || !day || !slots || !Array.isArray(slots)) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    
    // Only mentors can set their own availability
    if (authContext.role !== 'mentor' || authContext.uid !== mentor_id) {
      throw new functions.https.HttpsError('permission-denied', 'Can only set your own availability');
    }
    
    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    const db = admin.firestore();
    const batch = db.batch();
    
    // First, we need to find the user's document ID (which is based on their name, not UID)
    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Query for the user by their Firebase UID to get their actual document ID
    const userQuery = await usersCollection.where('firebase_uid', '==', mentor_id).limit(1).get();
    
    if (userQuery.empty) {
      throw new functions.https.HttpsError('not-found', 'User document not found');
    }
    
    const userDocSnapshot = userQuery.docs[0];
    const userDocId = userDocSnapshot.id; // This should be something like "Emerald_Nash"
    const userData = userDocSnapshot.data();
    
    console.log('🔍 AVAILABILITY: User lookup:');
    console.log('  - Firebase UID (mentor_id):', mentor_id);
    console.log('  - User Document ID:', userDocId);
    console.log('  - User Name:', userData.name);
    
    // Get user document reference for subcollection using the correct document ID
    const userDoc = usersCollection.doc(userDocId);
    const userAvailabilityCollection = userDoc.collection('availability');
    
    // Debug logging for paths
    console.log('🔍 === AVAILABILITY SAVE PATHS DEBUG ===');
    console.log('🔍 AVAILABILITY: Input Parameters:');
    console.log('  - University Path:', universityPath);
    console.log('  - Mentor Firebase UID:', mentor_id);
    console.log('  - User Document ID:', userDocId);
    console.log('  - Auth Context UID:', authContext.uid);
    console.log('  - Day:', day);
    console.log('🔍 AVAILABILITY: Collection References:');
    console.log('  - University Availability Collection:', availabilityCollection.path);
    console.log('  - User Document:', userDoc.path);
    console.log('  - User Availability Subcollection:', userAvailabilityCollection.path);
    console.log('🔍 AVAILABILITY: Expected Full Paths:');
    console.log('  - University Collection Doc will be at:', `${availabilityCollection.path}/${userDocId}_${day.replace(/\s/g, '_')}`);
    console.log('  - User Subcollection Doc will be at:', `${userAvailabilityCollection.path}/${userDocId}_${day.replace(/\s/g, '_')}`);
    console.log('🔍 =====================================');
    
    // First, delete existing availability for this day from both collections
    console.log('🔍 AVAILABILITY: Checking for existing slots to delete...');
    console.log('  - Querying university collection at:', availabilityCollection.path);
    console.log('  - Where mentor_id ==', mentor_id, 'AND day ==', day);
    
    const existingSlots = await availabilityCollection
      .where('mentor_id', '==', mentor_id)
      .where('day', '==', day)
      .get();
    
    console.log('  - Found', existingSlots.size, 'existing slots in university collection');
    
    console.log('  - Querying user subcollection at:', userAvailabilityCollection.path);
    console.log('  - Where day ==', day);
    
    const existingUserSlots = await userAvailabilityCollection
      .where('day', '==', day)
      .get();
    
    console.log('  - Found', existingUserSlots.size, 'existing slots in user subcollection');
    
    // Check if any slots are booked before deleting
    let hasBookedSlots = false;
    
    existingSlots.forEach(doc => {
      const data = doc.data() as Availability;
      if (data.slots && data.slots.some(slot => slot.is_booked)) {
        hasBookedSlots = true;
      } else {
        batch.delete(doc.ref);
      }
    });
    
    existingUserSlots.forEach(doc => {
      const data = doc.data() as Availability;
      if (data.slots && data.slots.some(slot => slot.is_booked)) {
        hasBookedSlots = true;
      } else {
        batch.delete(doc.ref);
      }
    });
    
    if (hasBookedSlots) {
      throw new functions.https.HttpsError(
        'failed-precondition', 
        'Cannot override availability with booked slots. Please cancel bookings first.'
      );
    }
    
    // Create a single document for the day with array of slots
    const availability: Omit<Availability, 'id'> = {
      mentor_id,
      day,
      slots: slots.map(slot => ({
        slot_start: slot.slot_start,
        slot_end: slot.slot_end,
        is_booked: false
      })),
      created_at: new Date(),
      updated_at: new Date()
    };
    
    // Generate a consistent ID based on user document ID and day
    const docId = `${userDocId}_${day.replace(/\s/g, '_')}`;
    
    // Debug logging for availability document creation
    console.log('🔍 === AVAILABILITY DOCUMENT CREATION DEBUG ===');
    console.log('🔍 AVAILABILITY: Generated Document ID:', docId);
    console.log('🔍 AVAILABILITY: Number of slots:', availability.slots.length);
    console.log('🔍 AVAILABILITY: Slot times:', availability.slots.map(s => s.slot_start).join(', '));
    
    // Add to university-level collection
    const universityDoc = availabilityCollection.doc(docId);
    console.log('🔍 AVAILABILITY: Creating document in UNIVERSITY collection:');
    console.log('  - Full path:', universityDoc.path);
    console.log('  - Parent collection:', universityDoc.parent.path);
    console.log('  - Document ID:', universityDoc.id);
    batch.set(universityDoc, availability);
    
    // Add to user subcollection with same ID for consistency
    const userSubDoc = userAvailabilityCollection.doc(docId);
    console.log('🔍 AVAILABILITY: Creating document in USER SUBCOLLECTION:');
    console.log('  - Full path:', userSubDoc.path);
    console.log('  - Parent collection:', userSubDoc.parent.path);
    console.log('  - Document ID:', userSubDoc.id);
    batch.set(userSubDoc, availability);
    
    console.log('🔍 AVAILABILITY: Committing batch write to both locations...');
    await batch.commit();
    console.log('✅ AVAILABILITY: Successfully saved to both university collection and user subcollection!');
    
    console.log(`Set availability for mentor ${mentor_id} on ${day} with ${slots.length} time slots`);
    
    return {
      success: true,
      data: {
        created: 1,  // One document created for the day
        doc_id: docId,
        slots_count: slots.length
      }
    };
    
  } catch (error) {
    console.error('Error setting availability:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to set availability');
  }
});

/**
 * Get mentor availability
 */
export const getMentorAvailability = functions.https.onCall(async (data: {
  universityPath: string;
  mentor_id: string;
  start_date?: string;
  end_date?: string;
}, context) => {
  try {
    const { universityPath, mentor_id, start_date, end_date } = data;
    
    if (!mentor_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Mentor ID required');
    }
    
    // Try to get from user subcollection first (primary source)
    const usersCollection = getUniversityCollection(universityPath, 'users');
    const userDoc = usersCollection.doc(mentor_id);
    const userAvailabilityCollection = userDoc.collection('availability');
    
    let query = userAvailabilityCollection;
    
    if (start_date) {
      query = query.where('day', '>=', start_date) as any;
    }
    
    if (end_date) {
      query = query.where('day', '<=', end_date) as any;
    }
    
    let snapshot = await query.orderBy('day').orderBy('slot_start').get();
    
    // If no results from subcollection, fallback to university-level collection
    if (snapshot.empty) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      let fallbackQuery = availabilityCollection.where('mentor_id', '==', mentor_id);
      
      if (start_date) {
        fallbackQuery = fallbackQuery.where('day', '>=', start_date);
      }
      
      if (end_date) {
        fallbackQuery = fallbackQuery.where('day', '<=', end_date);
      }
      
      snapshot = await fallbackQuery.orderBy('day').orderBy('slot_start').get();
    }
    
    const availability = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return {
      success: true,
      data: availability
    };
    
  } catch (error) {
    console.error('Error getting availability:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get availability');
  }
});

/**
 * Get available slots for booking (for mentees)
 */
export const getAvailableSlots = functions.https.onCall(async (data: {
  universityPath: string;
  mentor_id: string;
  start_date?: string;
  end_date?: string;
}, context) => {
  try {
    const { universityPath, mentor_id, start_date, end_date } = data;
    
    if (!mentor_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Mentor ID required');
    }
    
    // Try user subcollection first
    const usersCollection = getUniversityCollection(universityPath, 'users');
    const userDoc = usersCollection.doc(mentor_id);
    const userAvailabilityCollection = userDoc.collection('availability');
    
    let query = userAvailabilityCollection;
    
    if (start_date) {
      query = query.where('day', '>=', start_date) as any;
    }
    
    if (end_date) {
      query = query.where('day', '<=', end_date) as any;
    }
    
    let snapshot = await query.orderBy('day').get();
    
    // If no results from subcollection, fallback to university-level collection
    if (snapshot.empty) {
      const availabilityCollection = getUniversityCollection(universityPath, 'availability');
      let fallbackQuery = availabilityCollection.where('mentor_id', '==', mentor_id);
      
      if (start_date) {
        fallbackQuery = fallbackQuery.where('day', '>=', start_date);
      }
      
      if (end_date) {
        fallbackQuery = fallbackQuery.where('day', '<=', end_date);
      }
      
      snapshot = await fallbackQuery.orderBy('day').get();
    }
    
    // Return documents with the new array structure
    const availabilityDocs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return {
      success: true,
      data: availabilityDocs
    };
    
  } catch (error) {
    console.error('Error getting available slots:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get available slots');
  }
});

/**
 * Request a meeting at a custom time (for mentees)
 */
export const requestMeeting = functions.https.onCall(async (data: {
  universityPath: string;
  mentor_id: string;
  mentee_id: string;
  start_time: string;
  end_time?: string;
  topic?: string;
  location?: string;
  is_custom_time: boolean;
}, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, mentee_id, start_time, is_custom_time } = data;
    
    // Validate that the mentee is making the request
    if (authContext.uid !== mentee_id) {
      throw new functions.https.HttpsError('permission-denied', 'Can only request meetings for yourself');
    }
    
    // Create the meeting request
    const meetingData: CreateMeetingData = {
      universityPath,
      mentor_id,
      mentee_id,
      start_time,
      end_time: data.end_time,
      topic: data.topic,
      location: data.location,
    };
    
    // If it's a custom time, note it in the topic
    if (is_custom_time && !data.topic) {
      meetingData.topic = 'Custom time request';
    }
    
    // Create meeting directly (avoid circular dependency)
    const meeting: Omit<Meeting, 'id'> = {
      mentor_id,
      mentee_id,
      start_time,
      end_time: data.end_time,
      topic: is_custom_time && !data.topic ? 'Custom time request' : data.topic,
      location: data.location,
      status: 'pending',
      created_at: new Date()
    };

    const meetingsCollection = getUniversityCollection(universityPath, 'meetings');
    const result = await createDocument(meetingsCollection, meeting);

    if (result.success) {
      console.log(`Custom meeting request created: ${result.data?.id} in ${universityPath}`);
    }

    return result;
    
  } catch (error) {
    console.error('Error requesting meeting:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to request meeting');
  }
});