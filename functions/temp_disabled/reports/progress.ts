import * as functions from 'firebase-functions';
import { verifyAuth, verifyCoordinator } from '../utils/auth';
import { getUniversityCollection, createDocument, updateDocument, queryCollection } from '../utils/database';
import { ProgressReport } from '../types';

interface CreateProgressReportData {
  universityPath: string;
  mentee_id: string;
  mentor_id: string;
  report_period: string;
}

interface SubmitProgressReportData {
  universityPath: string;
  reportId: string;
  overall_score?: number;
  notes?: string;
}

/**
 * Generate a new progress report
 */
export const generateProgressReport = functions.https.onCall(async (data: CreateProgressReportData, context) => {
  try {
    // Verify authentication - mentors, mentees, and coordinators can create reports
    // const authContext = await verifyAuth(context);
    
    const { universityPath, mentee_id, mentor_id, report_period } = data;
    
    // Validate input
    if (!mentee_id || !mentor_id || !report_period) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Verify user can create report for this mentorship
    if (['mentor', 'mentee'].includes(authContext.role || '')) {
      if (authContext.uid !== mentor_id && authContext.uid !== mentee_id) {
        throw new functions.https.HttpsError('permission-denied', 'Can only create reports for your mentorship');
      }
    }

    // Check if report already exists for this period
    const reportsCollection = getUniversityCollection(universityPath, 'progress_reports');
    const existingReports = await queryCollection<ProgressReport>(reportsCollection, [
      { field: 'mentee_id', operator: '==', value: mentee_id },
      { field: 'mentor_id', operator: '==', value: mentor_id },
      { field: 'report_period', operator: '==', value: report_period }
    ]);

    if (existingReports.success && existingReports.data && existingReports.data.length > 0) {
      throw new functions.https.HttpsError('already-exists', 'Progress report already exists for this period');
    }

    // Create progress report document
    const progressReport: Omit<ProgressReport, 'id'> = {
      mentee_id,
      mentor_id,
      report_period,
      status: 'draft',
      overall_score: undefined,
      submission_date: undefined,
      review_date: undefined,
      created_at: new Date()
    };

    const result = await createDocument(reportsCollection, progressReport);

    if (result.success) {
      console.log(`Progress report created: ${result.data?.id} for ${mentee_id} by ${mentor_id}`);
    }

    return result;

  } catch (error) {
    console.error('Error creating progress report:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to create progress report');
  }
});

/**
 * Submit a progress report
 */
export const submitProgressReport = functions.https.onCall(async (data: SubmitProgressReportData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, reportId, overall_score, notes } = data;
    
    if (!reportId) {
      throw new functions.https.HttpsError('invalid-argument', 'Report ID required');
    }

    // Validate overall_score if provided
    if (overall_score !== undefined && (overall_score < 0 || overall_score > 100)) {
      throw new functions.https.HttpsError('invalid-argument', 'Overall score must be between 0 and 100');
    }

    // TODO: Add permission check to verify user can submit this specific report

    const reportsCollection = getUniversityCollection(universityPath, 'progress_reports');
    const result = await updateDocument(reportsCollection, reportId, {
      status: 'submitted',
      overall_score,
      notes,
      submission_date: new Date(),
      submitted_by: authContext.uid,
      updated_at: new Date()
    });

    if (result.success) {
      console.log(`Progress report submitted: ${reportId} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error submitting progress report:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to submit progress report');
  }
});

/**
 * Review a progress report (coordinator only)
 */
export const reviewProgressReport = functions.https.onCall(async (data: {
  universityPath: string;
  reportId: string;
  status: 'reviewed' | 'approved';
  reviewer_notes?: string;
}, context) => {
  try {
    // Verify coordinator permissions
    // const authContext = await verifyCoordinator(context, data.universityPath);
    
    const { universityPath, reportId, status, reviewer_notes } = data;
    
    if (!reportId || !status) {
      throw new functions.https.HttpsError('invalid-argument', 'Report ID and status required');
    }

    const reportsCollection = getUniversityCollection(universityPath, 'progress_reports');
    const result = await updateDocument(reportsCollection, reportId, {
      status,
      reviewer_notes,
      review_date: new Date(),
      reviewed_by: authContext.uid,
      updated_at: new Date()
    });

    if (result.success) {
      console.log(`Progress report reviewed: ${reportId} as ${status} by ${authContext.uid}`);
    }

    return result;

  } catch (error) {
    console.error('Error reviewing progress report:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to review progress report');
  }
});

/**
 * Get progress reports for a mentorship
 */
export const getProgressReports = functions.https.onCall(async (data: {
  universityPath: string;
  mentee_id?: string;
  mentor_id?: string;
  status?: string;
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, mentee_id, mentor_id, status } = data;
    
    const reportsCollection = getUniversityCollection(universityPath, 'progress_reports');
    
    // Build filters based on parameters
    const filters: Array<{ field: string; operator: FirebaseFirestore.WhereFilterOp; value: any }> = [];
    
    if (mentee_id) {
      filters.push({ field: 'mentee_id', operator: '==', value: mentee_id });
    }
    
    if (mentor_id) {
      filters.push({ field: 'mentor_id', operator: '==', value: mentor_id });
    }
    
    if (status) {
      filters.push({ field: 'status', operator: '==', value: status });
    }

    // If user is mentor or mentee, they can only see their own reports
    if (['mentor', 'mentee'].includes(authContext.role || '')) {
      if (!mentee_id && !mentor_id) {
        // Add filter to only show reports for this user
        filters.push({ field: 'mentor_id', operator: '==', value: authContext.uid });
        // Also add OR condition for mentee_id (would need separate query)
      }
    }

    const result = await queryCollection<ProgressReport>(reportsCollection, filters);

    if (result.success && result.data) {
      // Sort by created_at descending
      const sortedReports = result.data.sort((a, b) => 
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      );

      return {
        success: true,
        data: sortedReports
      };
    }

    return result;

  } catch (error) {
    console.error('Error getting progress reports:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get progress reports');
  }
});