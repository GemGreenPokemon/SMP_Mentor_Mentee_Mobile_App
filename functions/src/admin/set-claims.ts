import * as admin from 'firebase-admin';

// Initialize Firebase Admin (if not already done)
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Set super admin claims for a user
 * Run this script once to create your super admin user
 */
async function setSuperAdminClaims(email: string) {
  try {
    // Get user by email
    const user = await admin.auth().getUserByEmail(email);
    
    // Set custom claims
    await admin.auth().setCustomUserClaims(user.uid, {
      role: 'super_admin',
      university_path: null // Super admin can access all universities
    });
    
    console.log(`Super admin claims set for user: ${email} (${user.uid})`);
    
    // Force token refresh
    await admin.auth().revokeRefreshTokens(user.uid);
    console.log('Refresh tokens revoked - user must re-login');
    
  } catch (error) {
    console.error('Error setting super admin claims:', error);
  }
}

// Replace with your admin email
const ADMIN_EMAIL = 'admin@smp-mobile-app.com';
setSuperAdminClaims(ADMIN_EMAIL);