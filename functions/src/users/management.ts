import * as functions from 'firebase-functions';
import { verifyCoordinator, verifyAuth, setUserClaims } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument, deleteDocument } from '../utils/database';
import { User } from '../types';

interface CreateUserData {
  universityPath: string;
  name: string;
  email: string;
  userType: 'mentor' | 'mentee' | 'coordinator';
  student_id?: string;
  department?: string;
  year_major?: string;
}

interface UpdateUserData {
  universityPath: string;
  userId: string;
  name?: string;
  email?: string;
  department?: string;
  year_major?: string;
  acknowledgment_signed?: 'yes' | 'no' | 'not_applicable';
}

/**
 * Create a new user in the university system
 */
export const createUser = functions.https.onCall(async (data: CreateUserData, context) => {
  try {
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, name, email, userType, student_id, department, year_major } = data;
    
    // Validate input
    if (!name || !email || !userType) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Create user document
    const user: Omit<User, 'id'> = {
      name,
      email,
      userType,
      student_id,
      mentor: undefined,
      mentee: [],
      acknowledgment_signed: 'not_applicable',
      department,
      year_major,
      created_at: new Date()
    };

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const result = await createDocument(usersCollection, user);

    if (result.success && result.data) {
      // Set user claims for authentication
      try {
        await setUserClaims(result.data.id, {
          role: userType,
          university_path: universityPath
        });
      } catch (error) {
        console.warn('Failed to set user claims:', error);
      }

      console.log(`User created: ${result.data.id} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error creating user:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to create user');
  }
});

/**
 * Update an existing user
 */
export const updateUser = functions.https.onCall(async (data: UpdateUserData, context) => {
  try {
    // Verify authentication and permissions
    const authContext = await verifyAuth(context);
    
    const { universityPath, userId, ...updateData } = data;
    
    // Users can only update their own profile unless they're coordinators
    if (authContext.uid !== userId && !['coordinator', 'super_admin'].includes(authContext.role || '')) {
      throw new functions.https.HttpsError('permission-denied', 'Can only update own profile');
    }

    // Coordinators can only update users in their university
    if (['coordinator'].includes(authContext.role || '') && authContext.university_path !== universityPath) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied for this university');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const result = await updateDocument(usersCollection, userId, {
      ...updateData,
      updated_at: new Date()
    });

    if (result.success) {
      console.log(`User updated: ${userId} in ${universityPath}`);
    }

    return result;

  } catch (error) {
    console.error('Error updating user:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to update user');
  }
});

/**
 * Delete a user (coordinator only)
 */
export const deleteUser = functions.https.onCall(async (data: { universityPath: string; userId: string }, context) => {
  try {
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, userId } = data;
    
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const result = await deleteDocument(usersCollection, userId);

    if (result.success) {
      console.log(`User deleted: ${userId} in ${universityPath} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error deleting user:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to delete user');
  }
});

/**
 * Assign mentor to mentee
 */
export const assignMentor = functions.https.onCall(async (data: { 
  universityPath: string; 
  mentorId: string; 
  menteeId: string 
}, context) => {
  try {
    // Verify coordinator permissions
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, mentorId, menteeId } = data;
    
    if (!mentorId || !menteeId) {
      throw new functions.https.HttpsError('invalid-argument', 'Mentor and mentee IDs required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const mentorshipsCollection = getUniversityCollection(universityPath, 'mentorships');

    // Update mentee's mentor field
    await updateDocument(usersCollection, menteeId, {
      mentor: mentorId,
      updated_at: new Date()
    });

    // Create mentorship relationship
    await createDocument(mentorshipsCollection, {
      mentor_id: mentorId,
      mentee_id: menteeId,
      assigned_by: authContext.uid,
      overall_progress: 0.0,
      created_at: new Date()
    });

    console.log(`Mentor assigned: ${mentorId} -> ${menteeId} in ${universityPath}`);

    return {
      success: true,
      message: 'Mentor assigned successfully'
    };

  } catch (error) {
    console.error('Error assigning mentor:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to assign mentor');
  }
});