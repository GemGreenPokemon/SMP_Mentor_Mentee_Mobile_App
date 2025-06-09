import * as functions from 'firebase-functions';
import { verifyCoordinator } from '../utils/auth';
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
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
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
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, announcementId, ...updateData } = data;
    
    if (!announcementId) {
      throw new functions.https.HttpsError('invalid-argument', 'Announcement ID required');
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

    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
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
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, announcementId } = data;
    
    if (!announcementId) {
      throw new functions.https.HttpsError('invalid-argument', 'Announcement ID required');
    }

    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
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
    // Verify authentication
    await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, userType, limit = 20 } = data;
    
    const announcementsCollection = getUniversityCollection(universityPath, 'announcements');
    
    // Get announcements for this user type
    const snapshot = await announcementsCollection
      .where('target_audience', 'in', ['both', userType])
      .get();

    const announcements = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Announcement));

    const result = { success: true, data: announcements };

    if (result.success && result.data) {
      // Sort by created_at descending and apply limit
      const sortedAnnouncements = result.data
        .sort((a: Announcement, b: Announcement) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
        .slice(0, limit);

      return {
        success: true,
        data: sortedAnnouncements
      };
    }

    return result;

  } catch (error) {
    console.error('Error getting announcements:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get announcements');
  }
});