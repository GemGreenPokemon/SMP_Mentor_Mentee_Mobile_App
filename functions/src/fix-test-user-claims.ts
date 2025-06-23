import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

interface CustomClaims {
  role: 'mentor' | 'mentee' | 'coordinator' | 'developer' | 'super_admin';
  university_path: string | null;
}

async function fixTestUserClaims() {
  // Test user email - you can modify this as needed
  const testUserEmail = 'test@example.com';
  
  // Custom claims to set
  const customClaims = {
    role: 'mentor', // Change to 'mentee', 'coordinator', or 'developer' as needed
    university_path: 'universities/default_university' // Adjust path as needed
  };

  console.log('🔧 Starting to fix test user claims...');
  console.log(`📧 User email: ${testUserEmail}`);
  console.log(`🎯 Claims to set:`, customClaims);

  try {
    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(testUserEmail);
    console.log(`✅ Found user: ${userRecord.uid}`);
    console.log(`📋 Current claims:`, userRecord.customClaims || 'None');

    // Set custom claims
    await admin.auth().setCustomUserClaims(userRecord.uid, customClaims);
    console.log(`✅ Custom claims set successfully`);

    // Verify claims were set
    const updatedUser = await admin.auth().getUser(userRecord.uid);
    console.log(`✅ Verified claims:`, updatedUser.customClaims);

    // Force token refresh on next login
    await admin.auth().revokeRefreshTokens(userRecord.uid);
    console.log(`🔄 Revoked refresh tokens - user will get new claims on next login`);

    console.log('\n✨ Success! User claims have been updated.');
    console.log('📝 Note: The user needs to sign out and sign back in to receive the updated claims.');

  } catch (error) {
    console.error('❌ Error fixing user claims:', error);
    
    if ((error as any).code === 'auth/user-not-found') {
      console.error(`User with email "${testUserEmail}" not found.`);
      console.log('\n💡 Tip: Make sure the user exists in Firebase Auth first.');
    }
  }
}

// Run the function if this file is executed directly
if (require.main === module) {
  console.log('🚀 Firebase Fix Test User Claims Script');
  console.log('=====================================\n');

  // You can also accept email as command line argument
  const args = process.argv.slice(2);
  if (args.length > 0) {
    console.log(`📧 Using email from command line: ${args[0]}`);
    // Override the default email with command line argument
    (async () => {
      const testUserEmail = args[0];
      const role = args[1] || 'mentor';
      const universityPath = args[2] || 'universities/default_university';
      
      const customClaims = { role, university_path: universityPath };
      
      console.log(`📧 User email: ${testUserEmail}`);
      console.log(`🎯 Claims to set:`, customClaims);
      
      try {
        const userRecord = await admin.auth().getUserByEmail(testUserEmail);
        console.log(`✅ Found user: ${userRecord.uid}`);
        console.log(`📋 Current claims:`, userRecord.customClaims || 'None');
        
        await admin.auth().setCustomUserClaims(userRecord.uid, customClaims);
        console.log(`✅ Custom claims set successfully`);
        
        const updatedUser = await admin.auth().getUser(userRecord.uid);
        console.log(`✅ Verified claims:`, updatedUser.customClaims);
        
        await admin.auth().revokeRefreshTokens(userRecord.uid);
        console.log(`🔄 Revoked refresh tokens - user will get new claims on next login`);
        
        console.log('\n✨ Success! User claims have been updated.');
        console.log('📝 Note: The user needs to sign out and sign back in to receive the updated claims.');
      } catch (error) {
        console.error('❌ Error:', (error as Error).message);
      }
      
      process.exit(0);
    })();
  } else {
    // Run with default values
    fixTestUserClaims()
      .then(() => {
        console.log('\n👋 Script completed.');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n💥 Script failed:', error);
        process.exit(1);
      });
  }
}

export { fixTestUserClaims };