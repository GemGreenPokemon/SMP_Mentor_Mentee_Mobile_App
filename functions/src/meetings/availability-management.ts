import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, getDB } from '../utils/database';
import { getUserDocByUid, generateAvailabilityId, formatDate, getWeekNumber, getMonthYear, addHours } from './utils/meeting-helpers';

interface SetAvailabilityData {
  universityPath: string;
  mentor_id: string;
  day: string;
  slots: Array<{
    slot_start: string;
    slot_end?: string;
  }>;
}

interface GetAvailabilityData {
  universityPath: string;
  mentor_id: string;
  start_date?: string;
  end_date?: string;
}

/**
 * Set mentor availability using new structure
 * Creates individual documents for each availability slot
 */
export const setMentorAvailability = functions.https.onCall(async (data: SetAvailabilityData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, day, slots } = data;
    
    // Validate input
    if (!mentor_id || !day || !slots || slots.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Verify user is a mentor or admin
    if (!['mentor', 'coordinator', 'super_admin'].includes(authContext.role || '')) {
      throw new functions.https.HttpsError('permission-denied', 'Only mentors can set availability');
    }

    // If user is a mentor, they can only set their own availability
    if (authContext.role === 'mentor' && authContext.uid !== mentor_id) {
      throw new functions.https.HttpsError('permission-denied', 'Can only set your own availability');
    }

    // Get mentor document
    const mentorDoc = await getUserDocByUid(universityPath, mentor_id);
    if (!mentorDoc) {
      throw new functions.https.HttpsError('not-found', 'Mentor not found');
    }

    console.log(`Setting availability for mentor ${mentorDoc.id} on ${day}`);

    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    const db = getDB();
    
    // Generate document ID using mentor doc ID and date
    const docId = `${mentorDoc.id}_${day}`;
    
    // Transform slots to match Flutter's expected structure
    const slotsArray = slots.map(slot => ({
      slot_start: slot.slot_start,
      slot_end: slot.slot_end || addHours(slot.slot_start, 1),
      is_booked: false,
      mentee_id: null
    }));
    
    // Create availability document with array structure
    const availData = {
      id: docId,
      mentor_id: mentor_id,  // Flutter expects 'mentor_id' not 'mentor_uid'
      day: day,              // String date format as Flutter expects
      slots: slotsArray,     // Array of time slots
      synced: true,
      updated_at: FieldValue.serverTimestamp()
    };
    
    // Check for existing availability document for this day
    const existingDoc = await availabilityCollection.doc(docId).get();
    
    if (existingDoc.exists) {
      const existingData = existingDoc.data();
      // Check if any existing slots are booked
      const hasBookedSlots = existingData?.slots?.some((slot: any) => slot.is_booked) || false;
      
      if (hasBookedSlots) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Cannot override availability with booked slots. Please cancel bookings first.'
        );
      }
    }
    
    // Set the document (overwriting if exists)
    await availabilityCollection.doc(docId).set(availData);

    console.log(`Created availability for mentor ${mentorDoc.id} on ${day} with ${slotsArray.length} slots`);

    return {
      success: true,
      data: {
        created: 1,  // One document created for the day
        doc_id: docId,
        slots_count: slotsArray.length
      }
    };

  } catch (error) {
    console.error('Error setting mentor availability:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to set availability');
  }
});

/**
 * Get mentor availability from top-level collection
 */
export const getMentorAvailability = functions.https.onCall(async (data: GetAvailabilityData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, start_date, end_date } = data;
    
    if (!mentor_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Mentor ID required');
    }

    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    
    // Build query - now using 'mentor_id' and 'day' fields
    let query = availabilityCollection.where('mentor_id', '==', mentor_id);
    
    if (start_date) {
      query = query.where('day', '>=', start_date);
    }
    
    if (end_date) {
      query = query.where('day', '<=', end_date);
    }
    
    query = query.orderBy('day');
    
    const snapshot = await query.get();
    
    const availability = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        mentor_id: data.mentor_id,
        day: data.day,
        slots: data.slots || [],
        synced: data.synced || true,
        updated_at: data.updated_at?.toDate()?.toISOString() || null
      };
    });

    return {
      success: true,
      data: availability
    };

  } catch (error) {
    console.error('Error getting mentor availability:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get availability');
  }
});

/**
 * Get available (unbooked) slots for a mentor
 */
export const getAvailableSlots = functions.https.onCall(async (data: GetAvailabilityData, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, mentor_id, start_date, end_date } = data;
    
    if (!mentor_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Mentor ID required');
    }

    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    
    // Build query - using 'mentor_id' and 'day' fields
    let query = availabilityCollection.where('mentor_id', '==', mentor_id);
    
    if (start_date) {
      query = query.where('day', '>=', start_date);
    }
    
    if (end_date) {
      query = query.where('day', '<=', end_date);
    }
    
    query = query.orderBy('day');
    
    const snapshot = await query.get();
    
    const availableSlots: any[] = [];
    
    // Process each document and filter only unbooked slots
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.slots && Array.isArray(data.slots)) {
        // Filter unbooked slots
        const unbookedSlots = data.slots.filter((slot: any) => !slot.is_booked);
        if (unbookedSlots.length > 0) {
          availableSlots.push({
            id: doc.id,
            mentor_id: data.mentor_id,
            day: data.day,
            slots: unbookedSlots,
            synced: data.synced || true,
            updated_at: data.updated_at?.toDate()?.toISOString() || null
          });
        }
      }
    });

    return {
      success: true,
      data: availableSlots
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
 * Remove an availability slot
 */
export const removeAvailabilitySlot = functions.https.onCall(async (data: {
  universityPath: string;
  slot_id: string;
}, context) => {
  try {
    // Verify authentication
    const authContext = await verifyAuth(context);
    
    const { universityPath, slot_id } = data;
    
    if (!slot_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Slot ID required');
    }

    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    const slotDoc = await availabilityCollection.doc(slot_id).get();
    
    if (!slotDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Availability slot not found');
    }
    
    const slotData = slotDoc.data()!;
    
    // Check permissions
    if (!['coordinator', 'super_admin'].includes(authContext.role || '')) {
      if (authContext.uid !== slotData.mentor_uid) {
        throw new functions.https.HttpsError('permission-denied', 'Can only remove your own availability');
      }
    }
    
    // Check if slot is booked
    if (slotData.is_booked) {
      throw new functions.https.HttpsError('failed-precondition', 'Cannot remove booked availability slot');
    }
    
    await slotDoc.ref.delete();
    
    console.log(`Removed availability slot: ${slot_id}`);
    
    return {
      success: true,
      message: 'Availability slot removed successfully'
    };

  } catch (error) {
    console.error('Error removing availability slot:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to remove availability slot');
  }
});