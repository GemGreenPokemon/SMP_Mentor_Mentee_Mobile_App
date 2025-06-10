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
  acknowledgment_signed?: 'yes' | 'no' | 'not_applicable';
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
    // Temporarily skip authentication for testing
    // const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, name, email, userType, student_id, department, year_major, acknowledgment_signed } = data;
    
    // Validate input
    if (!name || !email || !userType) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Create user document - only include defined fields
    const user: any = {
      name,
      email,
      userType,
      mentee: [],
      acknowledgment_signed: acknowledgment_signed || 'not_applicable',
      created_at: new Date()
    };

    // Only add optional fields if they have values
    if (student_id) user.student_id = student_id;
    if (department) user.department = department;
    if (year_major) user.year_major = year_major;
    // Note: mentor field is intentionally omitted - it will be added when a mentor is assigned

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const result = await createDocument(usersCollection, user);

    if (result.success && result.data) {
      // Skip user claims for testing
      // try {
      //   await setUserClaims(result.data.id, {
      //     role: userType,
      //     university_path: universityPath
      //   });
      // } catch (error) {
      //   console.warn('Failed to set user claims:', error);
      // }

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
    // Temporarily skip authentication for testing
    // const authContext = await verifyAuth(context);
    
    const { universityPath, userId, ...updateData } = data;
    
    // Skip permission checks for testing
    // if (authContext.uid !== userId && !['coordinator', 'super_admin'].includes(authContext.role || '')) {
    //   throw new functions.https.HttpsError('permission-denied', 'Can only update own profile');
    // }

    // if (['coordinator'].includes(authContext.role || '') && authContext.university_path !== universityPath) {
    //   throw new functions.https.HttpsError('permission-denied', 'Access denied for this university');
    // }

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
    // Temporarily skip authentication for testing
    // const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, userId } = data;
    
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const result = await deleteDocument(usersCollection, userId);

    if (result.success) {
      console.log(`User deleted: ${userId} in ${universityPath}`);
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
 * Get all users in a university (coordinator only)
 */
export const getAllUsers = functions.https.onCall(async (data: { universityPath: string }, context) => {
  try {
    console.log('🔥 getAllUsers function called with data:', data);
    
    // Temporarily skip authentication for testing
    // const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath } = data;
    
    if (!universityPath) {
      throw new functions.https.HttpsError('invalid-argument', 'University path required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const snapshot = await usersCollection.get();
    
    const users = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`Retrieved ${users.length} users from ${universityPath}`);

    return {
      success: true,
      data: users
    };

  } catch (error) {
    console.error('Error getting users:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get users');
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
    // Temporarily skip authentication for testing
    // const authContext = await verifyCoordinator(context, data.universityPath);
    
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
      assigned_by: 'test-admin',
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