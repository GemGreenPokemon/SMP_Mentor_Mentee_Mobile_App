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
  return `${state}/${city}/${campus}`;
}

/**
 * Get collection reference for a university
 */
export function getUniversityCollection(universityPath: string, collectionName: string) {
  const db = getDB();
  return db.collection(universityPath).doc('data').collection(collectionName);
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