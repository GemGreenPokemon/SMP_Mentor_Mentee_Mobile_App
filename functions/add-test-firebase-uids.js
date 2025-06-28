const admin = require('firebase-admin');

// Set emulator environment variables (use 127.0.0.1 for Windows compatibility)
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

// Initialize admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'smp-mobile-app-462206'
  });
}

// Function to add firebase_uids to existing users in Firestore
async function addFirebaseUidsToUsers() {
  console.log('🔧 Adding test firebase_uids to existing users...');
  console.log('🔗 Connecting to Firestore emulator at 127.0.0.1:8080\n');
  
  try {
    const db = admin.firestore();
    
    // Query all users in the university collection
    const usersSnapshot = await db.collection('california_merced_uc_merced')
      .doc('data')
      .collection('users')
      .get();
    
    console.log(`📊 Found ${usersSnapshot.size} total users`);
    
    let updatedCount = 0;
    const batch = db.batch();
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      
      // Skip if already has firebase_uid
      if (userData.firebase_uid && userData.firebase_uid.trim() !== '') {
        console.log(`  ✓ ${doc.id} already has firebase_uid: ${userData.firebase_uid}`);
        continue;
      }
      
      // Generate a test firebase_uid (28 chars, similar to real Firebase UIDs)
      // Using TEST_ prefix to make it clear these are test UIDs
      const timestamp = Date.now().toString().substring(0, 10);
      const sanitizedId = doc.id.replace(/[^a-zA-Z0-9]/g, '').substring(0, 13);
      const testUid = `TEST${sanitizedId}${timestamp}`.substring(0, 28).padEnd(28, 'X');
      
      console.log(`  + Adding firebase_uid for ${doc.id}: ${testUid}`);
      
      batch.update(doc.ref, {
        firebase_uid: testUid
      });
      
      updatedCount++;
    }
    
    if (updatedCount > 0) {
      await batch.commit();
      console.log(`\n✅ Successfully updated ${updatedCount} users with test firebase_uids`);
    } else {
      console.log('\nℹ️  All users already have firebase_uids - no updates needed');
    }
    
  } catch (error) {
    console.error('❌ Error adding firebase_uids:', error);
    throw error;
  }
}

// Run the function
console.log('================================================');
console.log('Test Firebase UID Generator for Emulator');
console.log('================================================\n');

addFirebaseUidsToUsers()
  .then(() => {
    console.log('\n✅ Script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });