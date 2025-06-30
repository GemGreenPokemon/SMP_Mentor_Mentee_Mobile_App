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

async function setupEmulatorSuperAdmin() {
  console.log('🔧 Setting up emulator super-admin user...');
  console.log('🔗 Connecting to Auth emulator at 127.0.0.1:9099');
  console.log('🔗 Connecting to Firestore emulator at 127.0.0.1:8080\n');
  
  try {
    // Define super admin credentials (using your production email)
    const superAdminEmail = 'sunsetcoding.dev@gmail.com';
    const superAdminPassword = 'admin123456'; // Change this to your preferred password
    
    // Check if user already exists
    try {
      const existingUser = await admin.auth().getUserByEmail(superAdminEmail);
      console.log(`✅ Super admin already exists: ${existingUser.email}`);
      
      // Update custom claims in case they're missing
      await admin.auth().setCustomUserClaims(existingUser.uid, {
        role: 'super_admin',
        university_path: null
      });
      
      console.log('✅ Custom claims updated for super admin');
    } catch (error) {
      // User doesn't exist, continue to create
      if (error.code === 'auth/user-not-found') {
        // Create super admin user
        const adminUser = await admin.auth().createUser({
          email: superAdminEmail,
          password: superAdminPassword,
          emailVerified: true,
        });
        
        console.log(`✅ Super admin created: ${adminUser.email}`);
        
        // Set custom claims for super admin
        await admin.auth().setCustomUserClaims(adminUser.uid, {
          role: 'super_admin',
          university_path: null // null means access to all universities
        });
        
        console.log('✅ Custom claims set for super admin');
      } else {
        throw error;
      }
    }
    
    // Also create a secondary admin account if needed
    const secondaryAdminEmail = 'admin@smp-mobile-app.com';
    const secondaryAdminPassword = 'admin123456'; // Change this to your preferred password
    
    try {
      const secondaryAdmin = await admin.auth().getUserByEmail(secondaryAdminEmail);
      console.log(`✅ Secondary admin account already exists: ${secondaryAdmin.email}`);
      
      // Update custom claims
      await admin.auth().setCustomUserClaims(secondaryAdmin.uid, {
        role: 'super_admin',
        university_path: null
      });
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        const secondaryAdmin = await admin.auth().createUser({
          email: secondaryAdminEmail,
          password: secondaryAdminPassword,
          emailVerified: true,
        });
        
        await admin.auth().setCustomUserClaims(secondaryAdmin.uid, {
          role: 'super_admin',
          university_path: null
        });
        
        console.log(`✅ Secondary admin account created: ${secondaryAdmin.email}`);
      }
    }
    
    console.log('\n📋 Emulator Setup Complete!');
    console.log('==========================');
    console.log('Primary Super Admin Credentials:');
    console.log(`Email: ${superAdminEmail}`);
    console.log(`Password: ${superAdminPassword}`);
    console.log('\nSecondary Admin Credentials:');
    console.log(`Email: ${secondaryAdminEmail}`);
    console.log(`Password: ${secondaryAdminPassword}`);
    console.log('==========================\n');
    
  } catch (error) {
    console.error('❌ Error setting up emulator:', error);
    process.exit(1);
  }
}

// Function to create test users
async function createTestUsers() {
  console.log('\n🔧 Creating test users...');
  
  try {
    const db = admin.firestore();
    
    /* COMMENTED OUT MENTEE CREATION
    // Test user: Dasarathi Narayanan (Mentee)
    const dasarathiEmail = 'dnarayanan@ucmerced.edu';
    const dasarathiPassword = '123456';
    
    try {
      // Check if user already exists
      const existingUser = await admin.auth().getUserByEmail(dasarathiEmail);
      console.log(`✅ Test user Dasarathi already exists with UID: ${existingUser.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create the user in Firebase Auth
        const dasarathiUser = await admin.auth().createUser({
          email: dasarathiEmail,
          password: dasarathiPassword,
          displayName: 'Dasarathi Narayanan',
          emailVerified: true,
        });
        
        console.log(`✅ Created test user: Dasarathi Narayanan (${dasarathiUser.uid})`);
        
        // Set custom claims
        await admin.auth().setCustomUserClaims(dasarathiUser.uid, {
          role: 'mentee',
          university_path: 'california_merced_uc_merced'
        });
        
        // Create Firestore document
        const userDoc = {
          name: 'Dasarathi Narayanan',
          email: dasarathiEmail,
          firebase_uid: dasarathiUser.uid,
          user_type: 'mentee',
          student_id: '12345678',
          year_major: '1st year, Computer Science and Engineering(CSE)',
          department: 'Computer Science and Engineering(CSE)',
          major: 'Computer Science and Engineering',
          program: 'Computer Science and Engineering',
          mentor_id: 'Emerald_Nash', // Assign to existing mentor
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          email_verified: true,
          registration_complete: true,
          acknowledgment_submitted: false
        };
        
        await db.collection('california_merced_uc_merced')
          .doc('data')
          .collection('users')
          .doc('Dasarathi_Narayanan')
          .set(userDoc);
        
        console.log('✅ Created Firestore document for Dasarathi Narayanan');
        
        // Also add to mentees array of the mentor
        const mentorRef = db.collection('california_merced_uc_merced')
          .doc('data')
          .collection('users')
          .doc('Emerald_Nash');
          
        await mentorRef.update({
          mentees: admin.firestore.FieldValue.arrayUnion('Dasarathi_Narayanan')
        });
        
        console.log('✅ Added Dasarathi to Emerald Nash\'s mentees list');
      } else {
        throw error;
      }
    }
    
    console.log('\n📋 Test User Credentials:');
    console.log('==========================');
    console.log('Mentee - Dasarathi Narayanan:');
    console.log(`Email: ${dasarathiEmail}`);
    console.log(`Password: ${dasarathiPassword}`);
    console.log(`Role: mentee`);
    console.log(`Mentor: Emerald Nash`);
    console.log('==========================\n');
    */
    
    console.log('✅ Test user creation skipped (commented out)');
    
  } catch (error) {
    console.error('❌ Error creating test users:', error);
    throw error;
  }
}

// Run the setup
setupEmulatorSuperAdmin().then(async () => {
  console.log('✅ Emulator setup completed successfully');
  
  // Create test users
  await createTestUsers();
  
  console.log('\n✅ All emulator setup tasks completed!');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Setup failed:', error);
  process.exit(1);
});