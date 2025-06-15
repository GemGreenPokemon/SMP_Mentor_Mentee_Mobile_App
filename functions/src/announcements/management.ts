import * as functions from 'firebase-functions';
import { verifyAuth, verifyCoordinator, verifyMentor } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument, deleteDocument } from '../utils/database';
import { Announcement } from '../types';

interface CreateAnnouncementData {
  universityPath: string;
  title: string;
  content: string;
  priority: 'high' | 'medium' | 'low' | 'none';
  target_audience: 'mentors' | 'mentees' | 'both';
  time?: string;
}

interface UpdateAnnouncementData {
  universityPath: string;
  announcementId: string;
  title?: string;
  content?: string;
  priority?: 'high' | 'medium' | 'low' | 'none';
  target_audience?: 'mentors' | 'mentees' | 'both';
  time?: string;
}

/**
 * Create a new announcement
 */
export const createAnnouncement = functions.https.onCall(async (data: CreateAnnouncementData, context) => {
  try {
    console.log('📢 === CREATE ANNOUNCEMENT FUNCTION START ===');
    console.log('📢 Request data:', JSON.stringify(data));
    console.log('📢 Auth context exists:', !!context.auth);
    
    if (context.auth) {
      console.log('📢 Auth UID:', context.auth.uid);
      console.log('📢 Auth token claims:', JSON.stringify(context.auth.token));
    }
    
    // Verify mentor or coordinator permissions
    console.log('📢 Verifying mentor permissions...');
    const authContext = await verifyMentor(context);
    console.log('📢 ✅ Permissions verified. User role:', authContext.role);
    
    const { universityPath, title, content, priority, target_audience, time } = data;
    
    // Validate input
    if (!title || !content || !priority || !target_audience) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    if (title.length > 200) {
      throw new functions.https.HttpsError('invalid-argument', 'Title too long (max 200 characters)');
    }

    if (content.length > 2000) {
      throw new functions.https.HttpsError('invalid-argument', 'Content too long (max 2000 characters)');
    }

    // Create announcement document
    const announcement: Omit<Announcement, 'id'> = {
      title: title.trim(),
      content: content.trim(),
      time: time || new Date().toISOString(),
      priority,
      target_audience,
      created_at: new Date(),
      created_by: authContext.uid
    };

    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
    const result = await createDocument(announcementsCollection, announcement);

    if (result.success) {
      console.log(`Announcement created: ${result.data?.id} in ${universityPath} by ${authContext.uid}`);
      
      // TODO: Send push notifications to target audience
      // Implementation for push notifications would go here
    }

    return result;

  } catch (error) {
    console.error('Error creating announcement:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to create announcement');
  }
});

/**
 * Update an existing announcement
 */
export const updateAnnouncement = functions.https.onCall(async (data: UpdateAnnouncementData, context) => {
  try {
    // Verify mentor or coordinator permissions
    const authContext = await verifyMentor(context);
    
    const { universityPath, announcementId, ...updateData } = data;
    
    if (!announcementId) {
      throw new functions.https.HttpsError('invalid-argument', 'Announcement ID required');
    }

    // Check if user can edit this announcement
    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
    const announcementDoc = await announcementsCollection.doc(announcementId).get();
    
    if (!announcementDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Announcement not found');
    }
    
    const announcementData = announcementDoc.data() as Announcement;
    
    // Mentors can only edit their own announcements, coordinators can edit any
    if (authContext.role === 'mentor' && announcementData.created_by !== authContext.uid) {
      throw new functions.https.HttpsError('permission-denied', 'You can only edit your own announcements');
    }

    // Validate updated fields
    if (updateData.title && updateData.title.length > 200) {
      throw new functions.https.HttpsError('invalid-argument', 'Title too long (max 200 characters)');
    }

    if (updateData.content && updateData.content.length > 2000) {
      throw new functions.https.HttpsError('invalid-argument', 'Content too long (max 2000 characters)');
    }

    // Trim text fields
    const sanitizedData = {
      ...updateData,
      ...(updateData.title && { title: updateData.title.trim() }),
      ...(updateData.content && { content: updateData.content.trim() }),
      updated_at: new Date(),
      updated_by: authContext.uid
    };

    const result = await updateDocument(announcementsCollection, announcementId, sanitizedData);

    if (result.success) {
      console.log(`Announcement updated: ${announcementId} in ${universityPath} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error updating announcement:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to update announcement');
  }
});

/**
 * Delete an announcement
 */
export const deleteAnnouncement = functions.https.onCall(async (data: { 
  universityPath: string; 
  announcementId: string 
}, context) => {
  try {
    // Verify mentor or coordinator permissions
    const authContext = await verifyMentor(context);
    
    const { universityPath, announcementId } = data;
    
    if (!announcementId) {
      throw new functions.https.HttpsError('invalid-argument', 'Announcement ID required');
    }

    // Check if user can delete this announcement
    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
    const announcementDoc = await announcementsCollection.doc(announcementId).get();
    
    if (!announcementDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Announcement not found');
    }
    
    const announcementData = announcementDoc.data() as Announcement;
    
    // Mentors can only delete their own announcements, coordinators can delete any
    if (authContext.role === 'mentor' && announcementData.created_by !== authContext.uid) {
      throw new functions.https.HttpsError('permission-denied', 'You can only delete your own announcements');
    }

    const result = await deleteDocument(announcementsCollection, announcementId);

    if (result.success) {
      console.log(`Announcement deleted: ${announcementId} in ${universityPath} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error deleting announcement:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to delete announcement');
  }
});

/**
 * Get announcements for target audience
 */
export const getAnnouncements = functions.https.onCall(async (data: {
  universityPath: string;
  userType: 'mentor' | 'mentee' | 'coordinator';
  limit?: number;
}, context) => {
  try {
    // Verify authentication (any authenticated user can read announcements)
    const authContext = await verifyAuth(context);
    
    const { universityPath, userType, limit = 20 } = data;
    
    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
    
    // Get announcements for this user type
    const snapshot = await announcementsCollection
      .where('target_audience', 'in', ['both', userType])
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    const announcements = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Announcement));

    return {
      success: true,
      data: announcements
    };

  } catch (error) {
    console.error('Error getting announcements:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get announcements');
  }
});