/**
 * Meetings module - exports all meeting-related cloud functions
 * This is the new modular structure that replaces the monolithic management.ts
 */

// Meeting CRUD operations
export { createMeeting } from './create-meeting';
export { updateMeeting } from './update-meeting';

// Meeting status operations
export { cancelMeeting, acceptMeeting, rejectMeeting } from './meeting-status';

// Availability management
export { 
  setMentorAvailability, 
  getMentorAvailability, 
  getAvailableSlots,
  removeAvailabilitySlot 
} from './availability-management';

// Meeting requests
export { requestMeeting } from './request-meeting';