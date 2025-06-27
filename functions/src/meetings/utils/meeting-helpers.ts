import * as admin from 'firebase-admin';
import { getUniversityCollection } from '../../utils/database';

/**
 * Helper functions for meeting operations
 */

/**
 * Get user document by Firebase UID
 * Returns the document ID and data
 */
export async function getUserDocByUid(
  universityPath: string, 
  uid: string
): Promise<{ id: string; data: FirebaseFirestore.DocumentData } | null> {
  const usersCollection = getUniversityCollection(universityPath, 'users');
  
  // First try direct document ID lookup (in case uid is actually a doc ID)
  try {
    const docById = await usersCollection.doc(uid).get();
    if (docById.exists) {
      return { id: docById.id, data: docById.data()! };
    }
  } catch (e) {
    // Not a valid document ID, continue to firebase_uid lookup
  }
  
  // Query by firebase_uid
  const query = await usersCollection
    .where('firebase_uid', '==', uid)
    .limit(1)
    .get();
  
  if (!query.empty) {
    const doc = query.docs[0];
    return { id: doc.id, data: doc.data() };
  }
  
  return null;
}

/**
 * Generate human-readable meeting ID
 * Format: {mentorDocId}__{menteeDocId}__{timestamp}
 */
export function generateMeetingId(
  mentorDocId: string, 
  menteeDocId: string, 
  startTime: string | Date
): string {
  const timestamp = startTime instanceof Date 
    ? Math.floor(startTime.getTime() / 1000)
    : Math.floor(new Date(startTime).getTime() / 1000);
  
  return `${mentorDocId}__${menteeDocId}__${timestamp}`;
}

/**
 * Generate availability slot ID
 * Format: {mentorDocId}__{timestamp}
 */
export function generateAvailabilityId(
  mentorDocId: string,
  date: string,
  slotStart: string
): string {
  const timestamp = Math.floor(new Date(`${date}T${slotStart}`).getTime() / 1000);
  return `${mentorDocId}__${timestamp}`;
}

/**
 * Parse old availability ID format to get document ID and slot index
 * Format: "docId_slot_0"
 */
export function parseOldAvailabilityId(availabilityId: string): {
  docId: string;
  slotIndex: number;
} | null {
  const parts = availabilityId.split('_slot_');
  if (parts.length !== 2) return null;
  
  const docId = parts[0];
  const slotIndex = parseInt(parts[1]);
  
  if (isNaN(slotIndex)) return null;
  
  return { docId, slotIndex };
}

/**
 * Get week number for a date (ISO week number)
 */
export function getWeekNumber(date: Date): number {
  // Calculate the Thursday of the week (ISO 8601)
  const thursday = new Date(date);
  thursday.setDate(date.getDate() + (4 - date.getDay()));
  
  // Find the first Thursday of the year
  const firstThursday = new Date(thursday.getFullYear(), 0, 1);
  const daysToFirstThursday = firstThursday.getDay() === 4 
    ? 0 
    : (8 - firstThursday.getDay() + 4) % 7;
  firstThursday.setDate(firstThursday.getDate() + daysToFirstThursday);
  
  // Calculate week number
  const weekNumber = Math.floor((thursday.getTime() - firstThursday.getTime()) / (7 * 24 * 60 * 60 * 1000)) + 1;
  return weekNumber;
}

/**
 * Format date as YYYY-MM-DD
 */
export function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Get month-year string for grouping
 */
export function getMonthYear(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  return `${year}-${month}`;
}

/**
 * Add hours to a time string
 */
export function addHours(time: string, hours: number = 1): string {
  const [h, m] = time.split(':').map(Number);
  const newHours = (h + hours) % 24;
  return `${newHours.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
}