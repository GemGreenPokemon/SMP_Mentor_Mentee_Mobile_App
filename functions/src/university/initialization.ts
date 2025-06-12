import * as functions from 'firebase-functions';
import { verifySuperAdmin } from '../utils/auth';
import { getDB, getUniversityPath } from '../utils/database';
import { University } from '../types';

interface InitializeUniversityData {
  state: string;
  city: string;
  campus: string;
  universityName: string;
}

/**
 * Initialize a new university database structure
 * Only accessible by super admins
 */
export const initializeUniversity = functions.https.onCall(
  async (data: InitializeUniversityData, context) => {
    try {
      console.log('🔥 initializeUniversity function called with data:', data);
      
      // Re-enable authentication for production
      const authContext = await verifySuperAdmin(context);
      
      const { state, city, campus, universityName } = data;
      
      // Validate input
      if (!state || !city || !campus || !universityName) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
      }

      const universityPath = getUniversityPath(state, city, campus);
      console.log('🔥 Generated universityPath:', universityPath);
      
      const db = getDB();
      
      // Check if university already exists
      const universityDoc = await db.collection('universities').doc(universityPath).get();
      console.log('🔥 University doc exists:', universityDoc.exists);
      if (universityDoc.exists) {
        console.log('🔥 University already exists, throwing error');
        throw new functions.https.HttpsError('already-exists', 'University already initialized');
      }

      // Create university document
      const university: University = {
        id: universityPath,
        name: universityName,
        state,
        city,
        campus,
        path: universityPath,
        created_at: new Date(),
        created_by: authContext.uid
      };

      const batch = db.batch();

      // Create university record
      batch.set(db.collection('universities').doc(universityPath), university);

      // Initialize collections structure
      const collectionsToCreate = [
        'users',
        'mentorships',
        'meetings',
        'messages',
        'announcements',
        'progress_reports',
        'events',
        'resources',
        'checklists',
        'newsletters',
        'notifications'
      ];

      // Create initial documents in each collection to establish structure
      for (const collectionName of collectionsToCreate) {
        const collectionRef = db.collection(universityPath).doc('data').collection(collectionName);
        batch.set(collectionRef.doc('_metadata'), {
          collection: collectionName,
          created_at: new Date(),
          created_by: authContext.uid,
          version: 1
        });
      }

      // Create default settings document
      batch.set(db.collection(universityPath).doc('settings'), {
        university_name: universityName,
        academic_year: new Date().getFullYear(),
        mentorship_program_active: true,
        registration_open: true,
        created_at: new Date(),
        updated_at: new Date()
      });

      // Commit the batch
      await batch.commit();

      console.log(`University initialized: ${universityPath} by ${authContext.uid}`);

      return {
        success: true,
        universityPath,
        message: `University ${universityName} initialized successfully`,
        collections: collectionsToCreate
      };

    } catch (error) {
      console.error('Error initializing university:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError('internal', 'Failed to initialize university');
    }
  }
);

/**
 * Get all initialized universities
 */
export const getUniversities = functions.https.onCall(async (data, context) => {
  try {
    // Re-enable authentication for production
    await verifySuperAdmin(context);
    
    const db = getDB();
    const universitiesSnapshot = await db.collection('universities').get();
    
    const universities = universitiesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    return {
      success: true,
      data: universities
    };

  } catch (error) {
    console.error('Error getting universities:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get universities');
  }
});

/**
 * Delete university (use with extreme caution)
 */
export const deleteUniversity = functions.https.onCall(async (data: { universityPath: string }, context) => {
  try {
    // Re-enable authentication for production
    const authContext = await verifySuperAdmin(context);
    
    const { universityPath } = data;
    
    if (!universityPath) {
      throw new functions.https.HttpsError('invalid-argument', 'University path required');
    }

    const db = getDB();
    
    // TODO: Implement recursive deletion of all subcollections
    // For now, just delete the university record
    await db.collection('universities').doc(universityPath).delete();
    
    console.log(`University deleted: ${universityPath} by ${authContext.uid}`);

    return {
      success: true,
      message: `University ${universityPath} deleted successfully`
    };

  } catch (error) {
    console.error('Error deleting university:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to delete university');
  }
});