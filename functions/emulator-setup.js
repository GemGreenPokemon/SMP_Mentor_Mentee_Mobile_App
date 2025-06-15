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

// Run the setup
setupEmulatorSuperAdmin().then(() => {
  console.log('✅ Emulator setup completed successfully');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Setup failed:', error);
  process.exit(1);
});