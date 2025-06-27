import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import './local_database_service.dart';
import '../models/meeting.dart';
import '../models/availability.dart'; 

class LocalToFirestoreService {
  // Singleton pattern setup
  static final LocalToFirestoreService _instance = LocalToFirestoreService._internal();
  factory LocalToFirestoreService() => _instance;
  LocalToFirestoreService._internal();

  FirebaseFirestore? _firestore;
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  String _universityPath = '';

  // --- Initialization --- 

  Future<void> initialize({required String universityPath}) async {
    // Initialize Firebase if not already done (usually in main.dart)
    // await Firebase.initializeApp(); 
    _firestore = FirebaseFirestore.instance;
    _universityPath = universityPath;
    print('Firestore Initialized with university path: $_universityPath');
    // TODO: Add any further initialization logic (e.g., check connection)
  }

  // --- Synchronization Logic --- 

  Future<void> syncData() async {
    if (_firestore == null) {
      print('Firestore not initialized. Cannot sync.');
      return;
    }

    print('Starting data synchronization...');
    // TODO: Implement the logic to sync data between local SQLite and Firestore
    // 1. Fetch records from local DB where synced = 0 for each table.
    // 2. Push changes (create, update, delete) to Firestore.
    // 3. Update synced = 1 in local DB upon successful Firestore write.
    // 4. Potentially fetch changes from Firestore and update local DB (optional, depending on strategy).
    
    await _syncUsers();
    await _syncMentorships();
    await _syncAvailability();
    await _syncMeetings();
    await _syncResources();
    await _syncMessages();
    await _syncMeetingNotes();
    await _syncMeetingRatings();

    print('Data synchronization complete.');
  }

  // Placeholder sync methods for each table
  Future<void> _syncUsers() async {
     // TODO: Implement sync logic for users table
     print('Syncing users...');
  }

   Future<void> _syncMentorships() async {
     // TODO: Implement sync logic for mentorships table
     print('Syncing mentorships...');
  }

  Future<void> _syncAvailability() async {
    print('Syncing availability to top-level collection...');
    try {
      // Get unsynced availability from local DB
      final unsyncedAvailability = await _localDb.getUnsyncedAvailability();
      
      for (final availability in unsyncedAvailability) {
        // Write to top-level availability collection
        final docRef = _firestore!
            .collection('$_universityPath/data/availability')
            .doc(availability['id']);
            
        await docRef.set({
          'id': availability['id'],
          'mentor_uid': availability['mentor_uid'],
          'mentor_name': availability['mentor_name'],
          'date': Timestamp.fromDate(DateTime.parse(availability['date'])),
          'day_of_week': availability['day_of_week'],
          'start_time': availability['start_time'],
          'end_time': availability['end_time'],
          'is_booked': availability['is_booked'] == 1,
          'booked_by_uid': availability['booked_by_uid'],
          'booked_by_name': availability['booked_by_name'],
          'meeting_id': availability['meeting_id'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          // Composite fields for querying
          'mentor_date': '${availability['mentor_uid']}_${availability['date']}',
          'week_number': _getWeekNumber(DateTime.parse(availability['date'])),
          'month_year': _getMonthYear(DateTime.parse(availability['date'])),
        });
        
        // Mark as synced in local DB
        await _localDb.markAvailabilitySynced(availability['id']);
      }
      
      print('Synced ${unsyncedAvailability.length} availability records');
    } catch (e) {
      print('Error syncing availability: $e');
    }
  }

  Future<void> _syncMeetings() async {
    print('Syncing meetings to top-level collection...');
    try {
      // Get unsynced meetings from local DB
      final unsyncedMeetings = await _localDb.getUnsyncedMeetings();
      
      for (final meeting in unsyncedMeetings) {
        // Generate human-readable meeting ID if not present
        String meetingId = meeting['id'];
        if (!meetingId.contains('__')) {
          // Legacy ID, generate new one
          final timestamp = DateTime.parse(meeting['start_time']).millisecondsSinceEpoch ~/ 1000;
          meetingId = '${meeting['mentor_doc_id']}__${meeting['mentee_doc_id']}__$timestamp';
        }
        
        // Write to top-level meetings collection
        final docRef = _firestore!
            .collection('$_universityPath/data/meetings')
            .doc(meetingId);
            
        await docRef.set({
          'id': meetingId,
          'mentor_doc_id': meeting['mentor_doc_id'],
          'mentee_doc_id': meeting['mentee_doc_id'],
          'mentor_uid': meeting['mentor_uid'],
          'mentee_uid': meeting['mentee_uid'],
          'mentor_name': meeting['mentor_name'],
          'mentee_name': meeting['mentee_name'],
          'start_time': Timestamp.fromDate(DateTime.parse(meeting['start_time'])),
          'end_time': Timestamp.fromDate(DateTime.parse(meeting['end_time'])),
          'topic': meeting['topic'],
          'location': meeting['location'],
          'status': meeting['status'],
          'availability_id': meeting['availability_id'],
          'created_at': FieldValue.serverTimestamp(),
          'created_by': meeting['created_by'],
          'updated_at': FieldValue.serverTimestamp(),
          'updated_by': meeting['updated_by'],
          // Status tracking fields
          'accepted_at': meeting['accepted_at'] != null 
              ? Timestamp.fromDate(DateTime.parse(meeting['accepted_at'])) : null,
          'accepted_by': meeting['accepted_by'],
          'rejected_at': meeting['rejected_at'] != null 
              ? Timestamp.fromDate(DateTime.parse(meeting['rejected_at'])) : null,
          'rejected_by': meeting['rejected_by'],
          'rejection_reason': meeting['rejection_reason'],
          'cancelled_at': meeting['cancelled_at'] != null 
              ? Timestamp.fromDate(DateTime.parse(meeting['cancelled_at'])) : null,
          'cancelled_by': meeting['cancelled_by'],
          'cancellation_reason': meeting['cancellation_reason'],
        });
        
        // Mark as synced in local DB
        await _localDb.markMeetingSynced(meeting['id']);
      }
      
      print('Synced ${unsyncedMeetings.length} meeting records');
    } catch (e) {
      print('Error syncing meetings: $e');
    }
  }

  Future<void> _syncResources() async {
     // TODO: Implement sync logic for resources table
     print('Syncing resources...');
  }

   Future<void> _syncMessages() async {
     // TODO: Implement sync logic for messages table
     print('Syncing messages...');
  }

   Future<void> _syncMeetingNotes() async {
     // TODO: Implement sync logic for meeting_notes table
     print('Syncing meeting notes...');
  }

   Future<void> _syncMeetingRatings() async {
     // TODO: Implement sync logic for meeting_ratings table
     print('Syncing meeting ratings...');
  }

  // --- Helper methods ---

  int _getWeekNumber(DateTime date) {
    // Calculate ISO week number
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
  
  String _getMonthYear(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Fetch meetings from Firestore to update local DB
  Future<void> fetchMeetingsFromFirestore() async {
    if (_firestore == null || _universityPath.isEmpty) {
      print('Cannot fetch meetings: Firestore not initialized');
      return;
    }
    
    try {
      final snapshot = await _firestore!
          .collection('$_universityPath/data/meetings')
          .get();
          
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Update or insert into local DB
        await _localDb.upsertMeeting({
          'id': data['id'],
          'mentor_doc_id': data['mentor_doc_id'],
          'mentee_doc_id': data['mentee_doc_id'],
          'mentor_uid': data['mentor_uid'],
          'mentee_uid': data['mentee_uid'],
          'mentor_name': data['mentor_name'],
          'mentee_name': data['mentee_name'],
          'start_time': (data['start_time'] as Timestamp).toDate().toIso8601String(),
          'end_time': (data['end_time'] as Timestamp).toDate().toIso8601String(),
          'topic': data['topic'],
          'location': data['location'],
          'status': data['status'],
          'availability_id': data['availability_id'],
          'synced': 1,
        });
      }
      
      print('Fetched ${snapshot.docs.length} meetings from Firestore');
    } catch (e) {
      print('Error fetching meetings from Firestore: $e');
    }
  }

  // Fetch availability from Firestore to update local DB
  Future<void> fetchAvailabilityFromFirestore() async {
    if (_firestore == null || _universityPath.isEmpty) {
      print('Cannot fetch availability: Firestore not initialized');
      return;
    }
    
    try {
      final snapshot = await _firestore!
          .collection('$_universityPath/data/availability')
          .get();
          
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Update or insert into local DB
        await _localDb.upsertAvailability({
          'id': data['id'],
          'mentor_uid': data['mentor_uid'],
          'mentor_name': data['mentor_name'],
          'date': (data['date'] as Timestamp).toDate().toIso8601String(),
          'day_of_week': data['day_of_week'],
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'is_booked': data['is_booked'] ? 1 : 0,
          'booked_by_uid': data['booked_by_uid'],
          'booked_by_name': data['booked_by_name'],
          'meeting_id': data['meeting_id'],
          'synced': 1,
        });
      }
      
      print('Fetched ${snapshot.docs.length} availability records from Firestore');
    } catch (e) {
      print('Error fetching availability from Firestore: $e');
    }
  }

} 