import * as functions from 'firebase-functions';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument } from '../utils/database';

interface SyncData {
  universityPath: string;
  collection: string;
  operation: 'create' | 'update' | 'delete';
  document: any;
  localId?: string;
}

/**
 * Sync local database changes to Firestore
 */
export const syncLocalToFirestore = functions.https.onCall(async (data: SyncData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, collection, operation, document, localId } = data;
    
    // Validate input
    if (!collection || !operation || !document) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Validate collection name
    const allowedCollections = [
      'users', 'mentorships', 'meetings', 'messages', 'announcements',
      'progress_reports', 'events', 'resources', 'checklists', 'newsletters'
    ];

    if (!allowedCollections.includes(collection)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid collection name');
    }

    const firestoreCollection = getUniversityCollection(universityPath, collection);
    
    // Add sync metadata
    const syncMetadata = {
      synced_at: new Date(),
      synced_by: authContext.uid,
      local_id: localId
    };

    let result;

    switch (operation) {
      case 'create':
        // Remove local ID from document if present
        const { id, ...createData } = document;
        result = await createDocument(firestoreCollection, {
          ...createData,
          ...syncMetadata
        });
        break;

      case 'update':
        if (!document.id) {
          throw new functions.https.HttpsError('invalid-argument', 'Document ID required for update');
        }
        
        const { id: updateId, ...updateData } = document;
        result = await updateDocument(firestoreCollection, updateId, {
          ...updateData,
          ...syncMetadata
        });
        break;

      case 'delete':
        if (!document.id) {
          throw new functions.https.HttpsError('invalid-argument', 'Document ID required for delete');
        }
        
        // Soft delete by marking as deleted
        result = await updateDocument(firestoreCollection, document.id, {
          deleted: true,
          deleted_at: new Date(),
          deleted_by: authContext.uid
        });
        break;

      default:
        throw new functions.https.HttpsError('invalid-argument', 'Invalid operation');
    }

    if (result.success) {
      console.log(`Sync completed: ${operation} ${collection} in ${universityPath} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error syncing data:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to sync data');
  }
});

/**
 * Batch sync multiple documents
 */
export const batchSyncToFirestore = functions.https.onCall(async (data: {
  universityPath: string;
  operations: SyncData[];
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, operations } = data;
    
    if (!operations || operations.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'No operations provided');
    }

    if (operations.length > 100) {
      throw new functions.https.HttpsError('invalid-argument', 'Too many operations (max 100)');
    }

    const results = [];
    let successCount = 0;
    let errorCount = 0;

    // Process each operation
    for (const operation of operations) {
      try {
        // Manually process sync operation
        const { collection, operation: opType, document, localId } = operation;
        
        const firestoreCollection = getUniversityCollection(universityPath, collection);
        const syncMetadata = {
          synced_at: new Date(),
          synced_by: authContext.uid,
          local_id: localId
        };

        let syncResult;
        
        switch (opType) {
          case 'create':
            const { id, ...createData } = document;
            syncResult = await createDocument(firestoreCollection, { ...createData, ...syncMetadata });
            break;
          case 'update':
            if (!document.id) {
              throw new Error('Document ID required for update');
            }
            const { id: updateId, ...updateData } = document;
            syncResult = await updateDocument(firestoreCollection, updateId, { ...updateData, ...syncMetadata });
            break;
          case 'delete':
            if (!document.id) {
              throw new Error('Document ID required for delete');
            }
            syncResult = await updateDocument(firestoreCollection, document.id, {
              deleted: true,
              deleted_at: new Date(),
              deleted_by: authContext.uid
            });
            break;
          default:
            throw new Error('Invalid operation');
        }
        
        results.push({
          localId: operation.localId,
          success: syncResult?.success || false,
          data: syncResult?.data,
          error: syncResult?.error
        });

        if (syncResult?.success) {
          successCount++;
        } else {
          errorCount++;
        }
      } catch (error) {
        results.push({
          localId: operation.localId,
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
        errorCount++;
      }
    }

    console.log(`Batch sync completed: ${successCount} success, ${errorCount} errors for ${authContext.uid}`);

    return {
      success: true,
      results,
      summary: {
        total: operations.length,
        successful: successCount,
        failed: errorCount
      }
    };

  } catch (error) {
    console.error('Error in batch sync:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to batch sync data');
  }
});

/**
 * Get sync status for local database
 */
export const getSyncStatus = functions.https.onCall(async (data: {
  universityPath: string;
  collection: string;
  localIds: string[];
}, context) => {
  try {
    // Verify authentication
    // await verifyAuth(context);
    
    const { collection, localIds } = data;
    
    if (!collection || !localIds || localIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // TODO: Implement sync status checking
    // This would query Firestore to check which local documents have been synced
    
    const syncStatus = localIds.map(localId => ({
      localId,
      synced: false, // Placeholder - would check actual sync status
      lastSyncAt: null,
      firestoreId: null
    }));

    return {
      success: true,
      data: syncStatus
    };

  } catch (error) {
    console.error('Error getting sync status:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get sync status');
  }
});