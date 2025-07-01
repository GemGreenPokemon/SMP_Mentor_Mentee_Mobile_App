import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
console.log('[INIT] Initializing Firebase Admin SDK...');
try {
  admin.initializeApp();
  console.log('[INIT] Firebase Admin SDK initialized successfully');
  console.log('[INIT] Admin SDK check:', {
    hasAdmin: !!admin,
    hasFirestore: !!admin.firestore,
    hasAuth: !!admin.auth,
    hasFieldValue: !!admin.firestore?.FieldValue
  });
} catch (initError) {
  console.error('[INIT] Error initializing Firebase Admin SDK:', initError);
  throw initError;
}

// Import function modules
import { initializeUniversity } from './university/initialization';
import { createUser, updateUser, deleteUser, getAllUsers, bulkCreateUsers, bulkAssignMentors, validateNameForRegistration, migrateUserSubcollections, syncUserClaims } from './users/management';
import { checkMenteeAcknowledgment, submitMenteeAcknowledgment } from './users/acknowledgment';
import { createAnnouncement, updateAnnouncement, deleteAnnouncement, getAnnouncements } from './announcements/management';
import { setClaimsOnLogin, syncClaimsOnLogin, setClaimsOnRegistration } from './auth/triggers';
// Import from new modular meetings structure
import { 
  createMeeting, 
  updateMeeting, 
  cancelMeeting, 
  acceptMeeting, 
  rejectMeeting,
  setMentorAvailability,
  getMentorAvailability,
  getAvailableSlots,
  requestMeeting,
  removeAvailabilitySlot,
  hideMeeting as hideMeetingFunc,
  unhideMeeting as unhideMeetingFunc
} from './meetings';
import {
  createConversation,
  sendMessage,
  markMessagesRead,
  updateConversationSettings,
  getUserConversations
} from './messaging/conversations';
import {
  runUnitTest,
  runTestSuite
} from './testing/test-runner';
import {
  migrateMeetingsAndAvailability,
  cleanupOldMeetingSubcollections
} from './migrations/meetings-availability-migration';
// Temporarily commented out to avoid build errors:
// import { sendMessage, getChatHistory } from './messaging/chat';
// import { generateProgressReport, submitProgressReport } from './reports/progress';
// import { syncLocalToFirestore } from './sync/data-sync';

// University Management Functions
export const initUniversity = initializeUniversity;

// User Management Functions
export const createUserAccount = createUser;
export const updateUserAccount = updateUser;
export const deleteUserAccount = deleteUser;
export const getUsersList = getAllUsers;
export const bulkCreateUserAccounts = bulkCreateUsers;
export const bulkAssignMentorAccounts = bulkAssignMentors;
export const validateUserNameForRegistration = validateNameForRegistration;
export const migrateUserSubcollectionsForUniversity = migrateUserSubcollections;
export const syncUserClaimsForUniversity = syncUserClaims;

// Acknowledgment Functions
export const checkMenteeAcknowledgmentStatus = checkMenteeAcknowledgment;
export const submitMenteeAcknowledgmentForm = submitMenteeAcknowledgment;

// Auth Functions
export const onUserCreate = setClaimsOnLogin;
export const syncUserClaimsOnLogin = syncClaimsOnLogin;
export const setCustomClaimsOnRegistration = setClaimsOnRegistration;

// Announcement Functions
export const postAnnouncement = createAnnouncement;
export const updateAnnouncementDetails = updateAnnouncement;
export const removeAnnouncement = deleteAnnouncement;
export const getAnnouncementsList = getAnnouncements;

// Meeting Management Functions
export const scheduleMeeting = createMeeting;
export const updateMeetingDetails = updateMeeting;
export const deleteMeeting = cancelMeeting;
export const approveMeeting = acceptMeeting;
export const declineMeeting = rejectMeeting;

// Availability Management Functions
export const setAvailability = setMentorAvailability;
export const getAvailability = getMentorAvailability;
export const getBookableSlots = getAvailableSlots;
export const requestMeetingTime = requestMeeting;
export const removeAvailability = removeAvailabilitySlot;

// Meeting Visibility Functions  
export const hideMeeting = hideMeetingFunc;
export const unhideMeeting = unhideMeetingFunc;

// Messaging Functions (New Conversation-based)
export const createChatConversation = createConversation;
export const sendChatMessage = sendMessage;
export const markChatMessagesRead = markMessagesRead;
export const updateChatSettings = updateConversationSettings;
export const getUserChatConversations = getUserConversations;

// Old Messaging Functions (Deprecated)
// export const sendChatMessage = sendMessage;
// export const getChatMessages = getChatHistory;

// Progress Reporting Functions
// export const createProgressReport = generateProgressReport;
// export const submitReport = submitProgressReport;

// Data Synchronization Functions
// export const syncData = syncLocalToFirestore;

// Health check function
export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Test Runner Functions (Developer only)
export { runUnitTest, runTestSuite };

// Temporary debug function for Timestamp issue
export const debugTimestamp = functions.https.onCall(async (data, context) => {
  const results: any = {};
  
  // Test 1: Check admin
  results.adminExists = !!admin;
  results.adminFirestoreExists = !!admin.firestore;
  results.adminFirestoreType = typeof admin.firestore;
  
  // Test 2: Direct access
  try {
    results.directTimestamp = !!admin.firestore.Timestamp;
    results.directFieldValue = !!admin.firestore.FieldValue;
    results.directTimestampType = typeof admin.firestore.Timestamp;
  } catch (e: any) {
    results.directError = e.message;
  }
  
  // Test 3: Via function call
  try {
    const db = admin.firestore();
    results.dbExists = !!db;
    results.dbType = typeof db;
  } catch (e: any) {
    results.dbError = e.message;
  }
  
  // Test 4: Try the actual operation
  try {
    const testDate = new Date();
    const timestamp = admin.firestore.Timestamp.fromDate(testDate);
    results.timestampCreated = !!timestamp;
  } catch (e: any) {
    results.timestampError = e.message;
  }
  
  // Test 5: Import method
  try {
    const { Timestamp, FieldValue } = await import('firebase-admin/firestore');
    results.importedTimestamp = !!Timestamp;
    results.importedFieldValue = !!FieldValue;
    const importedTs = Timestamp.fromDate(new Date());
    results.importedTimestampWorks = !!importedTs;
  } catch (e: any) {
    results.importError = e.message;
  }
  
  return results;
});

// Migration Functions
export const migrateAllMeetingsAndAvailability = migrateMeetingsAndAvailability;
export const cleanupMeetingSubcollections = cleanupOldMeetingSubcollections;

// Utility Functions
