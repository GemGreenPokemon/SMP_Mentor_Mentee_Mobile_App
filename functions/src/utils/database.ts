import * as admin from 'firebase-admin';
import { DatabaseResult } from '../types';

/**
 * Get Firestore database instance
 */
export function getDB() {
  return admin.firestore();
}

/**
 * Generate university document path
 */
export function getUniversityPath(state: string, city: string, campus: string): string {
  return `${state}_${city}_${campus}`.toLowerCase().replace(/\s+/g, '_');
}

/**
 * Get collection reference for a university
 */
export function getUniversityCollection(universityPath: string, collectionName: string) {
  const db = getDB();
  return db.collection(universityPath).doc('data').collection(collectionName);
}

/**
 * Generate user document ID from name
 */
export function generateUserDocumentId(name: string): string {
  if (!name || typeof name !== 'string') {
    throw new Error('Name is required for ID generation');
  }

  // Split name by spaces and join with underscores
  // "Toby Sunset Jackson" -> "Toby_Sunset_Jackson"
  // "John Smith" -> "John_Smith"
  const cleanName = name
    .trim()
    .replace(/[^a-zA-Z0-9\s-']/g, '') // Remove special chars except spaces, hyphens, apostrophes
    .replace(/[-']/g, '_') // Convert hyphens and apostrophes to underscores
    .replace(/\s+/g, '_') // Replace spaces with underscores
    .replace(/_+/g, '_') // Replace multiple underscores with single
    .replace(/^_|_$/g, ''); // Remove leading/trailing underscores

  if (!cleanName) {
    throw new Error('Name resulted in empty ID after processing');
  }

  return cleanName;
}

/**
 * Check if document ID already exists and generate unique ID
 */
export async function generateUniqueUserId(
  collectionRef: FirebaseFirestore.CollectionReference,
  baseName: string
): Promise<string> {
  const baseId = generateUserDocumentId(baseName);
  let uniqueId = baseId;
  let counter = 2;

  // Check for collisions and append numbers if needed
  while (true) {
    const doc = await collectionRef.doc(uniqueId).get();
    if (!doc.exists) {
      return uniqueId;
    }
    uniqueId = `${baseId}_${counter}`;
    counter++;
  }
}

/**
 * Create document with custom ID
 */
export async function createDocumentWithCustomId<T extends { [x: string]: any }>(
  collectionRef: FirebaseFirestore.CollectionReference,
  data: T,
  customId: string
): Promise<DatabaseResult<{ id: string }>> {
  try {
    await collectionRef.doc(customId).set(data);
    return {
      success: true,
      data: { id: customId },
      message: 'Document created successfully'
    };
  } catch (error) {
    console.error('Error creating document with custom ID:', error);
    return {
      success: false,
      error: 'Failed to create document'
    };
  }
}

/**
 * Create document with auto-generated ID
 */
export async function createDocument<T extends { [x: string]: any }>(
  collectionRef: FirebaseFirestore.CollectionReference,
  data: T
): Promise<DatabaseResult<{ id: string }>> {
  try {
    const docRef = await collectionRef.add(data);
    return {
      success: true,
      data: { id: docRef.id },
      message: 'Document created successfully'
    };
  } catch (error) {
    console.error('Error creating document:', error);
    return {
      success: false,
      error: 'Failed to create document'
    };
  }
}

/**
 * Update document by ID
 */
export async function updateDocument<T>(
  collectionRef: FirebaseFirestore.CollectionReference,
  docId: string,
  data: Partial<T>
): Promise<DatabaseResult<null>> {
  try {
    await collectionRef.doc(docId).update(data);
    return {
      success: true,
      message: 'Document updated successfully'
    };
  } catch (error) {
    console.error('Error updating document:', error);
    return {
      success: false,
      error: 'Failed to update document'
    };
  }
}

/**
 * Delete document by ID
 */
export async function deleteDocument(
  collectionRef: FirebaseFirestore.CollectionReference,
  docId: string
): Promise<DatabaseResult<null>> {
  try {
    await collectionRef.doc(docId).delete();
    return {
      success: true,
      message: 'Document deleted successfully'
    };
  } catch (error) {
    console.error('Error deleting document:', error);
    return {
      success: false,
      error: 'Failed to delete document'
    };
  }
}

/**
 * Get document by ID
 */
export async function getDocument<T>(
  collectionRef: FirebaseFirestore.CollectionReference,
  docId: string
): Promise<DatabaseResult<T>> {
  try {
    const doc = await collectionRef.doc(docId).get();
    if (!doc.exists) {
      return {
        success: false,
        error: 'Document not found'
      };
    }

    return {
      success: true,
      data: { id: doc.id, ...doc.data() } as T
    };
  } catch (error) {
    console.error('Error getting document:', error);
    return {
      success: false,
      error: 'Failed to get document'
    };
  }
}

/**
 * Query collection with filters
 */
export async function queryCollection<T>(
  collectionRef: FirebaseFirestore.CollectionReference,
  filters: Array<{ field: string; operator: FirebaseFirestore.WhereFilterOp; value: any }>
): Promise<DatabaseResult<T[]>> {
  try {
    let query: FirebaseFirestore.Query = collectionRef;
    
    filters.forEach(filter => {
      query = query.where(filter.field, filter.operator, filter.value);
    });

    const snapshot = await query.get();
    const results = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as T));

    return {
      success: true,
      data: results
    };
  } catch (error) {
    console.error('Error querying collection:', error);
    return {
      success: false,
      error: 'Failed to query collection'
    };
  }
}