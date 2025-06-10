import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import function modules - temporarily only core database functions
import { initializeUniversity } from './university/initialization';
import { createUser, updateUser, deleteUser, getAllUsers, bulkCreateUsers, bulkAssignMentors } from './users/management';
// Temporarily commented out to avoid build errors:
// import { createMeeting, updateMeeting, deleteMeeting } from './meetings/management';
// import { sendMessage, getChatHistory } from './messaging/chat';
// import { createAnnouncement, updateAnnouncement } from './announcements/management';
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

// Temporarily commented out to avoid build errors:
// Meeting Management Functions
// export const scheduleMeeting = createMeeting;
// export const updateMeetingDetails = updateMeeting;
// export const cancelMeeting = deleteMeeting;

// Messaging Functions
// export const sendChatMessage = sendMessage;
// export const getChatMessages = getChatHistory;

// Announcement Functions
// export const postAnnouncement = createAnnouncement;
// export const updateAnnouncementDetails = updateAnnouncement;

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