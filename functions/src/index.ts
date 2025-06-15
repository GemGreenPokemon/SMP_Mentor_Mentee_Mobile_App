import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import function modules
import { initializeUniversity } from './university/initialization';
import { createUser, updateUser, deleteUser, getAllUsers, bulkCreateUsers, bulkAssignMentors, validateNameForRegistration, migrateUserSubcollections, syncUserClaims } from './users/management';
import { createAnnouncement, updateAnnouncement, deleteAnnouncement, getAnnouncements } from './announcements/management';
import { setClaimsOnLogin, syncClaimsOnLogin, setClaimsOnRegistration } from './auth/triggers';
import { 
  createMeeting, 
  updateMeeting, 
  cancelMeeting, 
  acceptMeeting, 
  rejectMeeting,
  setMentorAvailability,
  getMentorAvailability,
  getAvailableSlots,
  requestMeeting
} from './meetings/management';
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

// Messaging Functions
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