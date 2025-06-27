import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/meeting.dart';
import '../utils/meeting_constants.dart';
import '../utils/meeting_helpers.dart';
import '../managers/stream_manager.dart';
import '../managers/cache_manager.dart';

/// Repository for handling meeting-related operations
/// Uses top-level meetings collection instead of user subcollections
class MeetingRepository {
  final FirebaseFirestore _firestore;
  final String _universityPath;
  final MeetingStreamManager _streamManager = MeetingStreamManager();
  final MeetingCacheManager _cacheManager = MeetingCacheManager();
  
  MeetingRepository({
    required FirebaseFirestore firestore,
    required String universityPath,
  }) : _firestore = firestore,
       _universityPath = universityPath;
  
  /// Get the meetings collection reference
  CollectionReference<Map<String, dynamic>> get _meetingsCollection =>
      _firestore
          .collection(_universityPath)
          .doc('data')
          .collection(MeetingConstants.meetingsCollection);
  
  /// Create a new meeting in top-level collection
  Future<Meeting> createMeeting({
    required String mentorUid,
    required String menteeUid,
    required String mentorDocId,
    required String menteeDocId,
    required String mentorName,
    required String menteeName,
    required DateTime startTime,
    DateTime? endTime,
    String? topic,
    String? location,
    String? availabilitySlotId,
    String status = MeetingConstants.statusPending,
  }) async {
    try {
      // Generate human-readable meeting ID
      final meetingId = MeetingHelpers.generateMeetingId(mentorDocId, menteeDocId, startTime);
      
      final meetingData = {
        'id': meetingId,
        'mentor_doc_id': mentorDocId,
        'mentee_doc_id': menteeDocId,
        'mentor_uid': mentorUid,
        'mentee_uid': menteeUid,
        'mentor_name': mentorName,
        'mentee_name': menteeName,
        'start_time': Timestamp.fromDate(startTime),
        'end_time': endTime != null ? Timestamp.fromDate(endTime) : null,
        'topic': topic ?? '',
        'location': location ?? '',
        'status': status,
        'availability_slot_id': availabilitySlotId,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': menteeUid, // Assuming mentee creates the meeting request
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      // Use set() with custom ID instead of add()
      await _meetingsCollection.doc(meetingId).set(meetingData);
      
      return Meeting(
        id: meetingId,
        mentorId: mentorUid,
        menteeId: menteeUid,
        startTime: startTime.toIso8601String(),
        endTime: endTime?.toIso8601String(),
        topic: topic,
        location: location,
        status: status,
        availabilityId: availabilitySlotId,
        synced: true,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating meeting: $e');
      }
      throw Exception('Failed to create meeting: $e');
    }
  }
  
  /// Get meetings for a user (as mentor or mentee)
  Future<List<Meeting>> getMeetingsForUser(String userUid) async {
    try {
      // Query meetings where user is mentor
      final mentorQuery = await _meetingsCollection
          .where(MeetingConstants.fieldMentorUid, isEqualTo: userUid)
          .get();
      
      // Query meetings where user is mentee
      final menteeQuery = await _meetingsCollection
          .where(MeetingConstants.fieldMenteeUid, isEqualTo: userUid)
          .get();
      
      // Combine and deduplicate results
      final meetingsMap = <String, Meeting>{};
      
      for (final doc in [...mentorQuery.docs, ...menteeQuery.docs]) {
        if (!MeetingHelpers.shouldSkipDocument(doc.id)) {
          final meeting = _parseMeetingDoc(doc);
          meetingsMap[meeting.id] = meeting;
        }
      }
      
      // Sort by start time
      final meetings = meetingsMap.values.toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return meetings;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings for user: $e');
      }
      return [];
    }
  }
  
  /// Get meetings for a specific mentor-mentee pair
  Future<List<Meeting>> getMeetingsForPair(String mentorDocId, String menteeDocId) async {
    try {
      // Use the human-readable ID pattern to query efficiently
      final querySnapshot = await _meetingsCollection
          .where(FieldPath.documentId, 
                 isGreaterThanOrEqualTo: '${mentorDocId}${MeetingConstants.meetingIdSeparator}${menteeDocId}${MeetingConstants.meetingIdSeparator}')
          .where(FieldPath.documentId, 
                 isLessThan: '${mentorDocId}${MeetingConstants.meetingIdSeparator}${menteeDocId}${MeetingConstants.meetingIdSeparator}~')
          .orderBy(FieldPath.documentId)
          .get();
      
      return querySnapshot.docs
          .where((doc) => !MeetingHelpers.shouldSkipDocument(doc.id))
          .map(_parseMeetingDoc)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings for pair: $e');
      }
      return [];
    }
  }
  
  /// Subscribe to real-time meeting updates
  void subscribeToMeetings(String userUid) {
    // Cancel previous subscriptions
    _streamManager.cancelAllSubscriptions();
    
    print('\n🔍 === SUBSCRIBING TO MEETINGS (TOP-LEVEL) ===${'=' * 50}');
    print('🔍 User UID: $userUid');
    print('🔍 University Path: $_universityPath');
    
    // Create two queries for meetings where user is mentor OR mentee
    final mentorQuery = _meetingsCollection
        .where(MeetingConstants.fieldMentorUid, isEqualTo: userUid);
    final menteeQuery = _meetingsCollection
        .where(MeetingConstants.fieldMenteeUid, isEqualTo: userUid);
    
    final meetingsMap = <String, Meeting>{};
    
    void updateStream() {
      final meetings = meetingsMap.values.toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      _streamManager.updateMeetingsStream(meetings);
    }
    
    // Subscribe to meetings where user is mentor
    final mentorSubscription = mentorQuery.snapshots().listen(
      (snapshot) {
        print('DEBUG: Mentor meetings snapshot received with ${snapshot.docs.length} documents');
        
        // Remove old mentor meetings
        meetingsMap.removeWhere((key, value) => 
            value.mentorId == userUid && 
            !snapshot.docs.any((doc) => doc.id == key));
        
        // Add/update mentor meetings
        for (final doc in snapshot.docs) {
          if (!MeetingHelpers.shouldSkipDocument(doc.id)) {
            meetingsMap[doc.id] = _parseMeetingDoc(doc);
          }
        }
        
        updateStream();
      },
      onError: (error) {
        print('ERROR: Mentor meetings subscription error: $error');
        _streamManager.sendMeetingsError(error);
      },
    );
    
    // Subscribe to meetings where user is mentee
    final menteeSubscription = menteeQuery.snapshots().listen(
      (snapshot) {
        print('DEBUG: Mentee meetings snapshot received with ${snapshot.docs.length} documents');
        
        // Remove old mentee meetings
        meetingsMap.removeWhere((key, value) => 
            value.menteeId == userUid && 
            !snapshot.docs.any((doc) => doc.id == key));
        
        // Add/update mentee meetings
        for (final doc in snapshot.docs) {
          if (!MeetingHelpers.shouldSkipDocument(doc.id)) {
            meetingsMap[doc.id] = _parseMeetingDoc(doc);
          }
        }
        
        updateStream();
      },
      onError: (error) {
        print('ERROR: Mentee meetings subscription error: $error');
        _streamManager.sendMeetingsError(error);
      },
    );
    
    // Track subscriptions
    _streamManager.addSubscription(mentorSubscription);
    _streamManager.addSubscription(menteeSubscription);
  }
  
  /// Update meeting status
  Future<bool> updateMeetingStatus({
    required String meetingId,
    required String status,
    String? updatedBy,
    String? reason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': updatedBy,
      };
      
      // Add status-specific fields
      switch (status) {
        case MeetingConstants.statusAccepted:
          updateData['accepted_at'] = FieldValue.serverTimestamp();
          updateData['accepted_by'] = updatedBy;
          break;
        case MeetingConstants.statusRejected:
          updateData['rejected_at'] = FieldValue.serverTimestamp();
          updateData['rejected_by'] = updatedBy;
          if (reason != null) updateData['rejection_reason'] = reason;
          break;
        case MeetingConstants.statusCancelled:
          updateData['cancelled_at'] = FieldValue.serverTimestamp();
          updateData['cancelled_by'] = updatedBy;
          if (reason != null) updateData['cancellation_reason'] = reason;
          break;
      }
      
      await _meetingsCollection.doc(meetingId).update(updateData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating meeting status: $e');
      }
      return false;
    }
  }
  
  /// Update meeting details
  Future<bool> updateMeeting({
    required String meetingId,
    DateTime? startTime,
    DateTime? endTime,
    String? topic,
    String? location,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (startTime != null) updateData['start_time'] = Timestamp.fromDate(startTime);
      if (endTime != null) updateData['end_time'] = Timestamp.fromDate(endTime);
      if (topic != null) updateData['topic'] = topic;
      if (location != null) updateData['location'] = location;
      
      await _meetingsCollection.doc(meetingId).update(updateData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating meeting: $e');
      }
      return false;
    }
  }
  
  /// Delete a meeting
  Future<bool> deleteMeeting(String meetingId) async {
    try {
      await _meetingsCollection.doc(meetingId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting meeting: $e');
      }
      return false;
    }
  }
  
  /// Parse Firestore document to Meeting object
  Meeting _parseMeetingDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    
    return Meeting(
      id: doc.id,
      mentorId: data['mentor_uid'] ?? '',
      menteeId: data['mentee_uid'] ?? '',
      startTime: MeetingHelpers.timestampToIsoString(data['start_time']),
      endTime: data['end_time'] != null 
          ? MeetingHelpers.timestampToIsoString(data['end_time'])
          : null,
      topic: data['topic'],
      location: data['location'],
      status: data['status'] ?? MeetingConstants.statusPending,
      availabilityId: data['availability_slot_id'],
      synced: true,
    );
  }
}