import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { AuthContext } from '../types';

/**
 * Verify and extract authentication context from Firebase Auth
 */
export async function verifyAuth(context: functions.https.CallableContext): Promise<AuthContext> {
  console.log('🔒 verifyAuth: Checking authentication');
  
  if (!context.auth) {
    console.log('🔒 verifyAuth: ❌ No auth context');
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  console.log('🔒 verifyAuth: Auth UID:', context.auth.uid);
  console.log('🔒 verifyAuth: Full auth object:', JSON.stringify(context.auth));
  console.log('🔒 verifyAuth: Token object:', JSON.stringify(context.auth.token));
  
  // Custom claims can be at context.auth.token.role or context.auth.token (root level)
  const role = context.auth.token.role || context.auth.token['role'];
  let universityPath = context.auth.token.university_path || context.auth.token['university_path'];
  
  // Fallback mechanism for missing university_path
  if (!universityPath) {
    console.log('⚠️ verifyAuth: Warning - university_path is missing from token claims');
    console.log('⚠️ verifyAuth: Token claims available:', Object.keys(context.auth.token));
    console.log('⚠️ verifyAuth: Full token data:', JSON.stringify(context.auth.token));
    
    // TEMPORARY FALLBACK: Set default university_path if missing
    // TODO: This should be removed once all users have proper university_path claims
    universityPath = 'california_merced_uc_merced';
    console.log('⚠️ verifyAuth: Using fallback university_path:', universityPath);
    console.log('⚠️ verifyAuth: This is a temporary measure - user claims should be updated');
  } else {
    console.log('✅ verifyAuth: university_path found in claims:', universityPath);
  }
  
  const authContext = {
    uid: context.auth.uid,
    email: context.auth.token.email,
    role: role,
    university_path: universityPath
  };
  
  console.log('🔒 verifyAuth: Extracted auth context:', JSON.stringify(authContext));
  
  // Additional debug logging for missing university_path tracking
  if (context.auth.token.university_path === undefined && context.auth.token['university_path'] === undefined) {
    console.log('🔍 verifyAuth: Debug - User needs claims update:');
    console.log('  - UID:', context.auth.uid);
    console.log('  - Email:', context.auth.token.email);
    console.log('  - Role:', role);
    console.log('  - Applied fallback university_path:', universityPath);
  }
  
  return authContext;
}

/**
 * Verify super admin permissions for university management
 */
export async function verifySuperAdmin(context: functions.https.CallableContext): Promise<AuthContext> {
  const authContext = await verifyAuth(context);
  
  if (!authContext.role || authContext.role !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Super admin access required');
  }

  return authContext;
}

/**
 * Verify coordinator permissions for university-specific operations
 */
export async function verifyCoordinator(context: functions.https.CallableContext, universityPath: string): Promise<AuthContext> {
  const authContext = await verifyAuth(context);
  
  if (!authContext.role || !['coordinator', 'super_admin'].includes(authContext.role)) {
    throw new functions.https.HttpsError('permission-denied', 'Coordinator access required');
  }

  if (authContext.role === 'coordinator' && authContext.university_path !== universityPath) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied for this university');
  }

  return authContext;
}

/**
 * Verify mentor permissions
 */
export async function verifyMentor(context: functions.https.CallableContext): Promise<AuthContext> {
  console.log('🔒 verifyMentor: Starting verification');
  const authContext = await verifyAuth(context);
  
  console.log('🔒 verifyMentor: Auth context:', JSON.stringify(authContext));
  console.log('🔒 verifyMentor: User role:', authContext.role);
  
  if (!authContext.role || !['mentor', 'coordinator', 'super_admin'].includes(authContext.role)) {
    console.log('🔒 verifyMentor: ❌ Permission denied. Role:', authContext.role);
    throw new functions.https.HttpsError('permission-denied', 'Mentor access required');
  }

  console.log('🔒 verifyMentor: ✅ Permission granted');
  return authContext;
}

/**
 * Verify mentee permissions
 */
export async function verifyMentee(context: functions.https.CallableContext): Promise<AuthContext> {
  const authContext = await verifyAuth(context);
  
  if (!authContext.role || !['mentee', 'mentor', 'coordinator', 'super_admin'].includes(authContext.role)) {
    throw new functions.https.HttpsError('permission-denied', 'Mentee access required');
  }

  return authContext;
}

/**
 * Set custom claims for user authentication
 */
export async function setUserClaims(uid: string, claims: { role: string; university_path?: string }): Promise<void> {
  try {
    await admin.auth().setCustomUserClaims(uid, claims);
  } catch (error) {
    console.error('Error setting user claims:', error);
    throw new functions.https.HttpsError('internal', 'Failed to set user permissions');
  }
}