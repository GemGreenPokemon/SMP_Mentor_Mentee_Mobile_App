import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

// Initialize Firebase Admin SDK for emulator
const app = admin.initializeApp({
  projectId: 'smp-mentor-mentee-mobile-app',
});

const db = admin.firestore();

// Test users data
const testUsers = [
  // Mentors
  {
    uid: 'test-mentor-1',
    email: 'testmentor@ucmerced.edu',
    name: 'Test Mentor',
    userType: 'mentor',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0101',
    major: 'Computer Science',
    year: 'Faculty',
    bio: 'Experienced mentor dedicated to helping students succeed.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    menteeCount: 0,
    maxMentees: 5,
  },
  {
    uid: 'test-mentor-2',
    email: 'sarahmentor@ucmerced.edu',
    name: 'Sarah Johnson',
    userType: 'mentor',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0102',
    major: 'Biology',
    year: 'Graduate Student',
    bio: 'PhD student passionate about mentoring undergraduates in STEM.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    menteeCount: 0,
    maxMentees: 3,
  },
  {
    uid: 'test-mentor-3',
    email: 'mikementor@ucmerced.edu',
    name: 'Mike Chen',
    userType: 'mentor',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0103',
    major: 'Engineering',
    year: 'Faculty',
    bio: 'Engineering professor with 10 years of mentoring experience.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    menteeCount: 0,
    maxMentees: 4,
  },

  // Mentees
  {
    uid: 'test-mentee-1',
    email: 'testmentee@ucmerced.edu',
    name: 'Test Mentee',
    userType: 'mentee',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0201',
    major: 'Computer Science',
    year: 'Sophomore',
    bio: 'Eager to learn and grow in my academic journey.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    mentorId: null,
    goals: ['Improve GPA', 'Find internships', 'Network with professionals'],
  },
  {
    uid: 'test-mentee-2',
    email: 'emilymentee@ucmerced.edu',
    name: 'Emily Rodriguez',
    userType: 'mentee',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0202',
    major: 'Biology',
    year: 'Freshman',
    bio: 'First-year student looking for guidance in pre-med track.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    mentorId: null,
    goals: ['Medical school preparation', 'Research opportunities', 'Time management'],
  },
  {
    uid: 'test-mentee-3',
    email: 'alexmentee@ucmerced.edu',
    name: 'Alex Kim',
    userType: 'mentee',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0203',
    major: 'Engineering',
    year: 'Junior',
    bio: 'Engineering student interested in sustainable technology.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    mentorId: null,
    goals: ['Industry connections', 'Project guidance', 'Career planning'],
  },
  {
    uid: 'test-mentee-4',
    email: 'davidmentee@ucmerced.edu',
    name: 'David Park',
    userType: 'mentee',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0204',
    major: 'Computer Science',
    year: 'Senior',
    bio: 'Final year CS student preparing for tech industry.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
    mentorId: null,
    goals: ['Job search strategies', 'Interview preparation', 'Portfolio development'],
  },

  // Coordinator
  {
    uid: 'test-coordinator-1',
    email: 'testcoordinator@ucmerced.edu',
    name: 'Test Coordinator',
    userType: 'coordinator',
    university: 'uc_merced',
    campus: 'california_merced',
    phone: '555-0301',
    department: 'Student Success Center',
    role: 'Program Coordinator',
    bio: 'Managing the mentorship program for student success.',
    profilePicture: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
  },
];

// Function to create users
async function createTestUsers() {
  console.log('🚀 Starting test user creation...');
  
  const batch = db.batch();
  const usersCollection = db.collection('california_merced_uc_merced/data/users');
  
  for (const user of testUsers) {
    const userRef = usersCollection.doc(user.uid);
    batch.set(userRef, user);
    console.log(`✅ Preparing user: ${user.name} (${user.email})`);
  }

  try {
    await batch.commit();
    console.log('✅ All test users created successfully!');
    
    // Create some mentorship relationships
    console.log('\n📝 Creating mentorship relationships...');
    await createMentorships();
    
  } catch (error) {
    console.error('❌ Error creating test users:', error);
  }
}

// Function to create mentorship relationships
async function createMentorships() {
  const mentorshipsCollection = db.collection('california_merced_uc_merced/data/mentorships');
  
  const mentorships = [
    {
      mentorId: 'test-mentor-1',
      menteeId: 'test-mentee-1',
      status: 'active',
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      mentorId: 'test-mentor-2',
      menteeId: 'test-mentee-2',
      status: 'active',
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      mentorId: 'test-mentor-3',
      menteeId: 'test-mentee-3',
      status: 'active',
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  const batch = db.batch();
  
  for (const mentorship of mentorships) {
    const mentorshipRef = mentorshipsCollection.doc();
    batch.set(mentorshipRef, mentorship);
    
    // Update mentor's menteeCount
    const mentorRef = db.collection('california_merced_uc_merced/data/users').doc(mentorship.mentorId);
    batch.update(mentorRef, {
      menteeCount: admin.firestore.FieldValue.increment(1),
    });
    
    // Update mentee's mentorId
    const menteeRef = db.collection('california_merced_uc_merced/data/users').doc(mentorship.menteeId);
    batch.update(menteeRef, {
      mentorId: mentorship.mentorId,
    });
  }

  try {
    await batch.commit();
    console.log('✅ Mentorship relationships created successfully!');
  } catch (error) {
    console.error('❌ Error creating mentorships:', error);
  }
}

// Function to create test authentication users (optional - for Auth emulator)
async function createAuthUsers() {
  console.log('\n🔐 Creating authentication users...');
  
  const auth = admin.auth();
  
  for (const user of testUsers) {
    try {
      await auth.createUser({
        uid: user.uid,
        email: user.email,
        emailVerified: true,
        password: 'testpass123', // Default password for all test users
        displayName: user.name,
      });
      console.log(`✅ Auth user created: ${user.email}`);
    } catch (error: any) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`⚠️  Auth user already exists: ${user.email}`);
      } else {
        console.error(`❌ Error creating auth user ${user.email}:`, error);
      }
    }
  }
}

// Main execution
async function main() {
  try {
    // Check if we're connected to the emulator
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      console.warn('⚠️  Warning: FIRESTORE_EMULATOR_HOST not set. Make sure you\'re running the emulator!');
      console.log('Run: export FIRESTORE_EMULATOR_HOST="localhost:8080"');
    }

    await createTestUsers();
    await createAuthUsers();
    
    console.log('\n✅ Test data creation complete!');
    console.log('📝 Test user credentials:');
    console.log('   All passwords: testpass123');
    console.log('   Mentor: testmentor@ucmerced.edu');
    console.log('   Mentee: testmentee@ucmerced.edu');
    console.log('   Coordinator: testcoordinator@ucmerced.edu');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
main();