import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

interface MigrationStats {
  meetingsMigrated: number;
  availabilityMigrated: number;
  requestedMeetingsMigrated: number;
  errors: string[];
  startTime: Date;
  endTime?: Date;
}

/**
 * Migration script to move meetings and availability from user subcollections
 * to top-level university collections with new ID format
 */
export const migrateMeetingsAndAvailability = functions
  .runWith({ timeoutSeconds: 540, memory: '2GB' })
  .https.onCall(async (data, context) => {
    // Verify admin access
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can run migration'
      );
    }

    const { universityPath, dryRun = true } = data;
    if (!universityPath) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'universityPath is required'
      );
    }

    const db = admin.firestore();
    const stats: MigrationStats = {
      meetingsMigrated: 0,
      availabilityMigrated: 0,
      requestedMeetingsMigrated: 0,
      errors: [],
      startTime: new Date()
    };

    try {
      console.log(`Starting migration for ${universityPath} (dryRun: ${dryRun})`);

      // Get all users in the university
      const usersSnapshot = await db
        .collection(`${universityPath}/data/users`)
        .get();

      console.log(`Found ${usersSnapshot.size} users to process`);

      // Process each user
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const userUid = userData.firebase_uid;

        if (!userUid) {
          stats.errors.push(`User ${userId} missing firebase_uid`);
          continue;
        }

        try {
          // Migrate meetings
          await migrateMeetingsForUser(
            db, universityPath, userId, userUid, userData.name, stats, dryRun
          );

          // Migrate availability
          await migrateAvailabilityForUser(
            db, universityPath, userId, userUid, userData.name, stats, dryRun
          );

          // Migrate requestedMeetings (convert to pending meetings)
          await migrateRequestedMeetingsForUser(
            db, universityPath, userId, userUid, userData.name, stats, dryRun
          );

        } catch (error) {
          stats.errors.push(`Error processing user ${userId}: ${error}`);
          console.error(`Error processing user ${userId}:`, error);
        }
      }

      stats.endTime = new Date();
      const duration = (stats.endTime.getTime() - stats.startTime.getTime()) / 1000;

      console.log(`Migration completed in ${duration} seconds`);
      console.log(`Stats:`, stats);

      return {
        success: true,
        stats,
        message: dryRun 
          ? 'Dry run completed. No data was modified.' 
          : 'Migration completed successfully.'
      };

    } catch (error) {
      console.error('Migration failed:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Migration failed: ${error}`
      );
    }
  });

/**
 * Migrate meetings from user subcollection to top-level collection
 */
async function migrateMeetingsForUser(
  db: admin.firestore.Firestore,
  universityPath: string,
  userId: string,
  userUid: string,
  userName: string,
  stats: MigrationStats,
  dryRun: boolean
): Promise<void> {
  const meetingsRef = db.collection(
    `${universityPath}/data/users/${userId}/meetings`
  );
  const meetingsSnapshot = await meetingsRef.get();

  for (const meetingDoc of meetingsSnapshot.docs) {
    const meetingData = meetingDoc.data();
    
    try {
      // Determine if this user is mentor or mentee
      const isMentor = meetingData.mentor_id === userUid;
      const otherUserId = isMentor ? meetingData.mentee_id : meetingData.mentor_id;
      
      // Get the other user's document ID
      const otherUserQuery = await db
        .collection(`${universityPath}/data/users`)
        .where('firebase_uid', '==', otherUserId)
        .limit(1)
        .get();

      if (otherUserQuery.empty) {
        stats.errors.push(`Meeting ${meetingDoc.id}: Other user ${otherUserId} not found`);
        continue;
      }

      const otherUserDoc = otherUserQuery.docs[0];
      const otherUserData = otherUserDoc.data();

      // Generate new meeting ID
      const timestamp = meetingData.start_time?._seconds || 
        Math.floor(new Date(meetingData.start_time).getTime() / 1000);
      
      const mentorDocId = isMentor ? userId : otherUserDoc.id;
      const menteeDocId = isMentor ? otherUserDoc.id : userId;
      const newMeetingId = `${mentorDocId}__${menteeDocId}__${timestamp}`;

      // Create new meeting document structure
      const newMeetingData = {
        ...meetingData,
        id: newMeetingId,
        mentor_doc_id: mentorDocId,
        mentee_doc_id: menteeDocId,
        mentor_uid: isMentor ? userUid : otherUserId,
        mentee_uid: isMentor ? otherUserId : userUid,
        mentor_name: isMentor ? userName : otherUserData.name,
        mentee_name: isMentor ? otherUserData.name : userName,
        migrated_from: `users/${userId}/meetings/${meetingDoc.id}`,
        migrated_at: admin.firestore.FieldValue.serverTimestamp()
      };

      if (!dryRun) {
        // Check if meeting already exists (avoid duplicates)
        const existingMeeting = await db
          .doc(`${universityPath}/data/meetings/${newMeetingId}`)
          .get();

        if (!existingMeeting.exists) {
          await db
            .doc(`${universityPath}/data/meetings/${newMeetingId}`)
            .set(newMeetingData);
          stats.meetingsMigrated++;
        }
      } else {
        console.log(`Would create meeting: ${newMeetingId}`);
        stats.meetingsMigrated++;
      }

    } catch (error) {
      stats.errors.push(`Meeting ${meetingDoc.id}: ${error}`);
    }
  }
}

/**
 * Migrate availability from user subcollection to top-level collection
 */
async function migrateAvailabilityForUser(
  db: admin.firestore.Firestore,
  universityPath: string,
  userId: string,
  userUid: string,
  userName: string,
  stats: MigrationStats,
  dryRun: boolean
): Promise<void> {
  const availabilityRef = db.collection(
    `${universityPath}/data/users/${userId}/availability`
  );
  const availabilitySnapshot = await availabilityRef.get();

  for (const availDoc of availabilitySnapshot.docs) {
    const availData = availDoc.data();
    
    try {
      // Convert old slot structure to new individual documents
      const slots = availData.slots || [];
      const day = availData.day;

      for (let i = 0; i < slots.length; i++) {
        const slot = slots[i];
        
        // Generate new availability ID
        const slotTimestamp = new Date(`${day}T${slot.slot_start}`).getTime() / 1000;
        const newAvailId = `${userId}__${Math.floor(slotTimestamp)}`;

        // Create new availability document
        const newAvailData = {
          id: newAvailId,
          mentor_uid: userUid,
          mentor_doc_id: userId,
          mentor_name: userName,
          date: admin.firestore.Timestamp.fromDate(new Date(day)),
          day_of_week: new Date(day).toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase(),
          start_time: slot.slot_start,
          end_time: slot.slot_end || addHour(slot.slot_start),
          is_booked: slot.is_booked || false,
          booked_by_uid: slot.mentee_id || null,
          booked_by_name: null, // Will need to be filled later
          meeting_id: slot.meeting_id || null,
          created_at: availData.created_at || admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          // Composite fields for querying
          mentor_date: `${userUid}_${day}`,
          week_number: getWeekNumber(new Date(day)),
          month_year: new Date(day).toISOString().substring(0, 7),
          migrated_from: `users/${userId}/availability/${availDoc.id}`,
          migrated_at: admin.firestore.FieldValue.serverTimestamp()
        };

        if (!dryRun) {
          await db
            .doc(`${universityPath}/data/availability/${newAvailId}`)
            .set(newAvailData);
          stats.availabilityMigrated++;
        } else {
          console.log(`Would create availability: ${newAvailId}`);
          stats.availabilityMigrated++;
        }
      }

    } catch (error) {
      stats.errors.push(`Availability ${availDoc.id}: ${error}`);
    }
  }
}

/**
 * Migrate requestedMeetings to meetings with pending status
 */
async function migrateRequestedMeetingsForUser(
  db: admin.firestore.Firestore,
  universityPath: string,
  userId: string,
  userUid: string,
  userName: string,
  stats: MigrationStats,
  dryRun: boolean
): Promise<void> {
  const requestedRef = db.collection(
    `${universityPath}/data/users/${userId}/requestedMeetings`
  );
  const requestedSnapshot = await requestedRef.get();

  for (const requestedDoc of requestedSnapshot.docs) {
    const requestedData = requestedDoc.data();
    
    try {
      // Convert to meeting with pending status
      const meetingData = {
        ...requestedData,
        status: 'pending',
        migrated_from_requested: true
      };

      // Follow same logic as regular meetings
      const isMentor = requestedData.mentor_id === userUid;
      const otherUserId = isMentor ? requestedData.mentee_id : requestedData.mentor_id;
      
      const otherUserQuery = await db
        .collection(`${universityPath}/data/users`)
        .where('firebase_uid', '==', otherUserId)
        .limit(1)
        .get();

      if (otherUserQuery.empty) {
        stats.errors.push(`Requested meeting ${requestedDoc.id}: Other user not found`);
        continue;
      }

      const otherUserDoc = otherUserQuery.docs[0];
      const otherUserData = otherUserDoc.data();

      const timestamp = requestedData.start_time?._seconds || 
        Math.floor(new Date(requestedData.start_time).getTime() / 1000);
      
      const mentorDocId = isMentor ? userId : otherUserDoc.id;
      const menteeDocId = isMentor ? otherUserDoc.id : userId;
      const newMeetingId = `${mentorDocId}__${menteeDocId}__${timestamp}`;

      const newMeetingData = {
        ...meetingData,
        id: newMeetingId,
        mentor_doc_id: mentorDocId,
        mentee_doc_id: menteeDocId,
        mentor_uid: isMentor ? userUid : otherUserId,
        mentee_uid: isMentor ? otherUserId : userUid,
        mentor_name: isMentor ? userName : otherUserData.name,
        mentee_name: isMentor ? otherUserData.name : userName,
        migrated_from: `users/${userId}/requestedMeetings/${requestedDoc.id}`,
        migrated_at: admin.firestore.FieldValue.serverTimestamp()
      };

      if (!dryRun) {
        const existingMeeting = await db
          .doc(`${universityPath}/data/meetings/${newMeetingId}`)
          .get();

        if (!existingMeeting.exists) {
          await db
            .doc(`${universityPath}/data/meetings/${newMeetingId}`)
            .set(newMeetingData);
          stats.requestedMeetingsMigrated++;
        }
      } else {
        console.log(`Would create meeting from requested: ${newMeetingId}`);
        stats.requestedMeetingsMigrated++;
      }

    } catch (error) {
      stats.errors.push(`Requested meeting ${requestedDoc.id}: ${error}`);
    }
  }
}

// Helper functions
function addHour(time: string): string {
  const [hours, minutes] = time.split(':').map(Number);
  const newHours = (hours + 1) % 24;
  return `${newHours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
}

function getWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
}

/**
 * Cleanup function to remove old subcollections after successful migration
 */
export const cleanupOldMeetingSubcollections = functions
  .runWith({ timeoutSeconds: 540, memory: '2GB' })
  .https.onCall(async (data, context) => {
    // Verify admin access
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can run cleanup'
      );
    }

    const { universityPath, dryRun = true } = data;
    if (!universityPath) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'universityPath is required'
      );
    }

    const db = admin.firestore();
    let deletedCount = 0;

    try {
      // Get all users
      const usersSnapshot = await db
        .collection(`${universityPath}/data/users`)
        .get();

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        // Delete meetings subcollection
        const meetingsRef = db.collection(
          `${universityPath}/data/users/${userId}/meetings`
        );
        const meetings = await meetingsRef.get();
        
        for (const doc of meetings.docs) {
          if (!dryRun) {
            await doc.ref.delete();
          }
          deletedCount++;
        }

        // Delete availability subcollection  
        const availRef = db.collection(
          `${universityPath}/data/users/${userId}/availability`
        );
        const avail = await availRef.get();
        
        for (const doc of avail.docs) {
          if (!dryRun) {
            await doc.ref.delete();
          }
          deletedCount++;
        }

        // Delete requestedMeetings subcollection
        const requestedRef = db.collection(
          `${universityPath}/data/users/${userId}/requestedMeetings`
        );
        const requested = await requestedRef.get();
        
        for (const doc of requested.docs) {
          if (!dryRun) {
            await doc.ref.delete();
          }
          deletedCount++;
        }
      }

      return {
        success: true,
        deletedCount,
        message: dryRun 
          ? `Dry run: Would delete ${deletedCount} documents` 
          : `Deleted ${deletedCount} documents from subcollections`
      };

    } catch (error) {
      console.error('Cleanup failed:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Cleanup failed: ${error}`
      );
    }
  });