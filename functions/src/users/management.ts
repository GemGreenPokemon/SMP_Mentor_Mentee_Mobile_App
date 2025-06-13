import * as functions from 'firebase-functions';
import { verifyCoordinator, verifyAuth, setUserClaims } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument, deleteDocument, createDocumentWithCustomId, generateUniqueUserId, initializeUserSubcollections } from '../utils/database';
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
  mentor?: string;
  mentee?: string[] | string;
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

interface BulkCreateUserData {
  universityPath: string;
  users: Array<{
    name: string;
    email: string;
    userType: 'mentor' | 'mentee' | 'coordinator';
    student_id?: string;
    department?: string;
    year_major?: string;
    acknowledgment_signed?: 'yes' | 'no' | 'not_applicable';
    career_aspiration?: string;
    topics?: string[];
    import_source?: string;
    import_batch_id?: string;
    mentor?: string;
    mentee?: string[] | string;
  }>;
}

interface BulkAssignMentorsData {
  universityPath: string;
  assignments: Array<{
    mentorName: string;
    menteeName: string;
    notes?: string;
  }>;
}

/**
 * Create a new user in the university system
 */
export const createUser = functions.https.onCall(async (data: CreateUserData, context) => {
  try {
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, name, email, userType, student_id, department, year_major, acknowledgment_signed, mentor, mentee } = data;
    
    // Validate input
    if (!name || !email || !userType) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Create user document - only include defined fields
    const user: any = {
      name,
      email,
      userType,
      acknowledgment_signed: acknowledgment_signed || 'not_applicable',
      created_at: new Date()
    };

    // Only add optional fields if they have values
    if (student_id) user.student_id = student_id;
    if (department) user.department = department;
    if (year_major) user.year_major = year_major;
    
    // Add mentor/mentee relationships if provided
    if (mentor) user.mentor = mentor;
    if (mentee) {
      user.mentee = Array.isArray(mentee) ? mentee : [mentee];
    } else {
      user.mentee = []; // Default empty array if no mentees
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Generate unique user ID from name
    const userId = await generateUniqueUserId(usersCollection, name);
    const result = await createDocumentWithCustomId(usersCollection, user, userId);

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
      
      // Initialize user subcollections
      try {
        const subcollectionResult = await initializeUserSubcollections(
          universityPath, 
          result.data.id, 
          authContext.uid || 'system'
        );
        
        if (subcollectionResult.success) {
          console.log(`✅ Subcollections initialized for user ${result.data.id}: ${subcollectionResult.data?.createdSubcollections.join(', ')}`);
        } else {
          console.warn(`⚠️ Failed to initialize some subcollections for user ${result.data.id}: ${subcollectionResult.error}`);
        }
      } catch (subcollectionError) {
        console.error(`Error initializing subcollections for user ${result.data.id}:`, subcollectionError);
        // Don't fail the entire user creation if subcollections fail
      }
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
    // Re-enable authentication for production
    const authContext = await verifyAuth(context);
    
    const { universityPath, userId, ...updateData } = data;
    
    // Re-enable permission checks for production
    if (authContext.uid !== userId && !['coordinator', 'super_admin'].includes(authContext.role || '')) {
      throw new functions.https.HttpsError('permission-denied', 'Can only update own profile');
    }

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
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
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
    
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
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
    // Re-enable authentication for production
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

/**
 * Bulk create users from Excel import
 */
export const bulkCreateUsers = functions.https.onCall(async (data: BulkCreateUserData, context) => {
  try {
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, users } = data;
    
    if (!users || users.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'No users provided');
    }

    if (users.length > 100) {
      throw new functions.https.HttpsError('invalid-argument', 'Maximum 100 users per batch');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const results = {
      success: 0,
      failed: 0,
      errors: [] as Array<{ index: number; error: string; userData: any }>,
      createdUsers: [] as Array<{ id: string; name: string; email: string }>,
      subcollectionStats: {
        successful: 0,
        failed: 0,
        errors: [] as Array<{ userId: string; error: string }>
      }
    };

    // Process users in batch
    for (let i = 0; i < users.length; i++) {
      const userData = users[i];
      
      try {
        // Validate required fields
        if (!userData.name || !userData.email || !userData.userType) {
          throw new Error('Missing required fields: name, email, or userType');
        }

        // Check for duplicate email
        const existingUserQuery = await usersCollection.where('email', '==', userData.email).get();
        if (!existingUserQuery.empty) {
          throw new Error(`User with email ${userData.email} already exists`);
        }

        // Create user document with enhanced fields
        const user: any = {
          name: userData.name.trim(),
          email: userData.email.toLowerCase().trim(),
          userType: userData.userType,
          acknowledgment_signed: userData.acknowledgment_signed || 'not_applicable',
          created_at: new Date(),
          import_source: userData.import_source || 'excel',
          import_batch_id: userData.import_batch_id || 'unknown'
        };

        // Add optional fields only if they have values
        if (userData.student_id) user.student_id = userData.student_id.trim();
        if (userData.department) user.department = userData.department.trim();
        if (userData.year_major) user.year_major = userData.year_major.trim();
        if (userData.career_aspiration) user.career_aspiration = userData.career_aspiration.trim();
        if (userData.topics && userData.topics.length > 0) user.topics = userData.topics;
        
        // Add mentor/mentee relationships if provided
        if (userData.mentor) user.mentor = userData.mentor.trim();
        if (userData.mentee) {
          user.mentee = Array.isArray(userData.mentee) ? userData.mentee : [userData.mentee];
        } else {
          user.mentee = []; // Default empty array if no mentees
        }

        // Generate unique user ID from name
        const userId = await generateUniqueUserId(usersCollection, userData.name);
        const result = await createDocumentWithCustomId(usersCollection, user, userId);

        if (result.success && result.data) {
          results.success++;
          results.createdUsers.push({
            id: result.data.id,
            name: userData.name,
            email: userData.email
          });
          
          console.log(`Bulk: User created ${result.data.id} (${userData.name}) in ${universityPath}`);
          
          // Initialize subcollections for the created user
          try {
            const subcollectionResult = await initializeUserSubcollections(
              universityPath, 
              result.data.id, 
              authContext.uid || 'system'
            );
            
            if (subcollectionResult.success) {
              results.subcollectionStats.successful++;
              console.log(`Bulk: ✅ Subcollections initialized for user ${result.data.id}: ${subcollectionResult.data?.createdSubcollections.join(', ')}`);
            } else {
              results.subcollectionStats.failed++;
              results.subcollectionStats.errors.push({
                userId: result.data.id,
                error: subcollectionResult.error || 'Unknown subcollection error'
              });
              console.warn(`Bulk: ⚠️ Failed to initialize subcollections for user ${result.data.id}: ${subcollectionResult.error}`);
            }
          } catch (subcollectionError) {
            results.subcollectionStats.failed++;
            results.subcollectionStats.errors.push({
              userId: result.data.id,
              error: subcollectionError instanceof Error ? subcollectionError.message : String(subcollectionError)
            });
            console.error(`Bulk: Error initializing subcollections for user ${result.data.id}:`, subcollectionError);
            // Don't fail the entire user creation if subcollections fail
          }
        } else {
          throw new Error(result.error || 'Failed to create user');
        }

      } catch (error) {
        results.failed++;
        results.errors.push({
          index: i,
          error: error instanceof Error ? error.message : String(error),
          userData: { name: userData.name, email: userData.email }
        });
        
        console.error(`Bulk: Failed to create user at index ${i}:`, error);
      }
    }

    console.log(`Bulk import completed: ${results.success} created, ${results.failed} failed in ${universityPath}`);
    console.log(`Subcollections: ${results.subcollectionStats.successful} successful, ${results.subcollectionStats.failed} failed`);

    return {
      success: results.failed === 0,
      message: `Bulk import completed: ${results.success} users created, ${results.failed} failed. Subcollections: ${results.subcollectionStats.successful} successful, ${results.subcollectionStats.failed} failed`,
      results
    };

  } catch (error) {
    console.error('Error in bulk create users:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to bulk create users');
  }
});

/**
 * Bulk assign mentors to mentees by name matching
 */
export const bulkAssignMentors = functions.https.onCall(async (data: BulkAssignMentorsData, context) => {
  try {
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, assignments } = data;
    
    if (!assignments || assignments.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'No assignments provided');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const mentorshipsCollection = getUniversityCollection(universityPath, 'mentorships');
    
    // Get all users first for name-to-ID mapping
    const usersSnapshot = await usersCollection.get();
    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    })) as Array<{
      id: string;
      name: string;
      userType: string;
      mentor?: string;
      [key: string]: any;
    }>;

    const results = {
      success: 0,
      failed: 0,
      errors: [] as Array<{ index: number; error: string; assignment: any }>,
      assignments: [] as Array<{ mentorName: string; menteeName: string; mentorId: string; menteeId: string }>
    };

    // Process assignments
    for (let i = 0; i < assignments.length; i++) {
      const assignment = assignments[i];
      
      try {
        // Find mentor by name
        const mentor = users.find(u => 
          u.name.toLowerCase().trim() === assignment.mentorName.toLowerCase().trim() && 
          u.userType === 'mentor'
        );
        
        if (!mentor) {
          throw new Error(`Mentor not found: ${assignment.mentorName}`);
        }

        // Find mentee by name
        const mentee = users.find(u => 
          u.name.toLowerCase().trim() === assignment.menteeName.toLowerCase().trim() && 
          u.userType === 'mentee'
        );
        
        if (!mentee) {
          throw new Error(`Mentee not found: ${assignment.menteeName}`);
        }

        // Check if mentee already has a mentor
        if (mentee.mentor) {
          console.warn(`Mentee ${assignment.menteeName} already has a mentor, reassigning...`);
        }

        // Update mentee's mentor field
        await updateDocument(usersCollection, mentee.id, {
          mentor: mentor.id,
          updated_at: new Date()
        });

        // Create mentorship relationship
        await createDocument(mentorshipsCollection, {
          mentor_id: mentor.id,
          mentee_id: mentee.id,
          assigned_by: authContext.uid,
          overall_progress: 0.0,
          notes: assignment.notes || '',
          created_at: new Date()
        });

        results.success++;
        results.assignments.push({
          mentorName: assignment.mentorName,
          menteeName: assignment.menteeName,
          mentorId: mentor.id,
          menteeId: mentee.id
        });

        console.log(`Bulk: Assigned mentor ${assignment.mentorName} -> ${assignment.menteeName} in ${universityPath}`);

      } catch (error) {
        results.failed++;
        results.errors.push({
          index: i,
          error: error instanceof Error ? error.message : String(error),
          assignment: { mentorName: assignment.mentorName, menteeName: assignment.menteeName }
        });
        
        console.error(`Bulk: Failed to assign mentor at index ${i}:`, error);
      }
    }

    console.log(`Bulk mentor assignment completed: ${results.success} assigned, ${results.failed} failed in ${universityPath}`);

    return {
      success: results.failed === 0,
      message: `Bulk mentor assignment completed: ${results.success} assignments made, ${results.failed} failed`,
      results
    };

  } catch (error) {
    console.error('Error in bulk assign mentors:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to bulk assign mentors');
  }
});

/**
 * Migrate existing users to add missing subcollections
 */
export const migrateUserSubcollections = functions.https.onCall(async (data: {
  universityPath: string;
  userIds?: string[];  // Optional: migrate specific users, otherwise migrate all
  dryRun?: boolean;    // Optional: just check what would be migrated without doing it
}, context) => {
  try {
    // Re-enable authentication for production
    const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, userIds, dryRun = false } = data;
    
    if (!universityPath) {
      throw new functions.https.HttpsError('invalid-argument', 'University path required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    
    // Get users to migrate
    let usersToCheck: Array<{ id: string; name: string; userType: string }>;
    
    if (userIds && userIds.length > 0) {
      // Migrate specific users
      usersToCheck = [];
      for (const userId of userIds) {
        try {
          const userDoc = await usersCollection.doc(userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            usersToCheck.push({
              id: userId,
              name: userData?.name || 'Unknown',
              userType: userData?.userType || 'unknown'
            });
          }
        } catch (error) {
          console.warn(`Failed to fetch user ${userId}:`, error);
        }
      }
    } else {
      // Migrate all users
      const usersSnapshot = await usersCollection.get();
      usersToCheck = usersSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name || 'Unknown',
        userType: doc.data().userType || 'unknown'
      }));
    }

    const subcollections = ['checklists', 'availability', 'requestedMeetings', 'messages', 'notes', 'ratings'];
    const migrationResults = {
      totalUsers: usersToCheck.length,
      usersNeedingMigration: 0,
      usersAlreadyMigrated: 0,
      migrationSuccessful: 0,
      migrationFailed: 0,
      errors: [] as Array<{ userId: string; userName: string; error: string }>,
      details: [] as Array<{ 
        userId: string; 
        userName: string; 
        missingSubcollections: string[]; 
        migrated: boolean;
        error?: string;
      }>
    };

    // Check each user for missing subcollections
    for (const user of usersToCheck) {
      try {
        const userDocRef = usersCollection.doc(user.id);
        const missingSubcollections: string[] = [];

        // Check which subcollections are missing
        for (const subcollectionName of subcollections) {
          const metadataDoc = await userDocRef.collection(subcollectionName).doc('_metadata').get();
          if (!metadataDoc.exists) {
            missingSubcollections.push(subcollectionName);
          }
        }

        if (missingSubcollections.length === 0) {
          // User already has all subcollections
          migrationResults.usersAlreadyMigrated++;
          migrationResults.details.push({
            userId: user.id,
            userName: user.name,
            missingSubcollections: [],
            migrated: false
          });
        } else {
          // User needs migration
          migrationResults.usersNeedingMigration++;
          
          if (dryRun) {
            // Just record what would be migrated
            migrationResults.details.push({
              userId: user.id,
              userName: user.name,
              missingSubcollections,
              migrated: false
            });
          } else {
            // Perform the migration
            try {
              const subcollectionResult = await initializeUserSubcollections(
                universityPath,
                user.id,
                authContext.uid || 'migration'
              );

              if (subcollectionResult.success) {
                migrationResults.migrationSuccessful++;
                migrationResults.details.push({
                  userId: user.id,
                  userName: user.name,
                  missingSubcollections,
                  migrated: true
                });
                console.log(`Migration: ✅ Migrated user ${user.id} (${user.name}): ${subcollectionResult.data?.createdSubcollections.join(', ')}`);
              } else {
                migrationResults.migrationFailed++;
                migrationResults.errors.push({
                  userId: user.id,
                  userName: user.name,
                  error: subcollectionResult.error || 'Unknown error'
                });
                migrationResults.details.push({
                  userId: user.id,
                  userName: user.name,
                  missingSubcollections,
                  migrated: false,
                  error: subcollectionResult.error
                });
                console.error(`Migration: ❌ Failed to migrate user ${user.id} (${user.name}): ${subcollectionResult.error}`);
              }
            } catch (migrationError) {
              migrationResults.migrationFailed++;
              const errorMessage = migrationError instanceof Error ? migrationError.message : String(migrationError);
              migrationResults.errors.push({
                userId: user.id,
                userName: user.name,
                error: errorMessage
              });
              migrationResults.details.push({
                userId: user.id,
                userName: user.name,
                missingSubcollections,
                migrated: false,
                error: errorMessage
              });
              console.error(`Migration: ❌ Exception during migration for user ${user.id} (${user.name}):`, migrationError);
            }
          }
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        migrationResults.errors.push({
          userId: user.id,
          userName: user.name,
          error: `Failed to check user: ${errorMessage}`
        });
        console.error(`Migration: Error checking user ${user.id}:`, error);
      }
    }

    const summary = dryRun 
      ? `Dry run completed: ${migrationResults.usersNeedingMigration} users need migration, ${migrationResults.usersAlreadyMigrated} already migrated`
      : `Migration completed: ${migrationResults.migrationSuccessful} successful, ${migrationResults.migrationFailed} failed, ${migrationResults.usersAlreadyMigrated} already migrated`;

    console.log(`User subcollection migration - ${summary}`);

    return {
      success: migrationResults.migrationFailed === 0,
      message: summary,
      dryRun,
      results: migrationResults
    };

  } catch (error) {
    console.error('Error in migrateUserSubcollections:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to migrate user subcollections');
  }
});

/**
 * Validate if a name is approved for registration (NAME-ONLY WHITELIST)
 * Used during registration to check if user is allowed to sign up
 */
export const validateNameForRegistration = functions.https.onCall(async (data: { 
  universityPath: string; 
  name: string 
}, context) => {
  try {
    console.log('🔥 validateNameForRegistration function called with data:', data);
    
    // This function doesn't require authentication as it's used during registration
    // before the user has an account
    
    const { universityPath, name } = data;
    
    if (!universityPath || !name) {
      throw new functions.https.HttpsError('invalid-argument', 'University path and name are required');
    }

    const usersCollection = getUniversityCollection(universityPath, 'users');
    const snapshot = await usersCollection.where('name', '==', name.trim()).get();
    
    const isApproved = !snapshot.empty;
    
    console.log(`Name validation for "${name}" in ${universityPath}: ${isApproved ? 'APPROVED' : 'NOT APPROVED'}`);

    return {
      success: true,
      approved: isApproved,
      message: isApproved ? 'Name found in approved list' : 'Name not found in approved list'
    };

  } catch (error) {
    console.error('Error validating name for registration:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to validate name for registration');
  }
});