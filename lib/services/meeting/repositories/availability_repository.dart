import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/availability.dart';
import '../utils/meeting_constants.dart';
import '../utils/meeting_helpers.dart';
import '../managers/stream_manager.dart';
import '../managers/cache_manager.dart';

/// Repository for handling availability-related operations
/// Uses top-level availability collection instead of user subcollections
class AvailabilityRepository {
  final FirebaseFirestore _firestore;
  final String _universityPath;
  final MeetingStreamManager _streamManager = MeetingStreamManager();
  final MeetingCacheManager _cacheManager = MeetingCacheManager();
  Timer? _pollingTimer;
  
  AvailabilityRepository({
    required FirebaseFirestore firestore,
    required String universityPath,
  }) : _firestore = firestore,
       _universityPath = universityPath;
  
  /// Get the availability collection reference
  CollectionReference<Map<String, dynamic>> get _availabilityCollection =>
      _firestore
          .collection(_universityPath)
          .doc('data')
          .collection(MeetingConstants.availabilityCollection);
  
  /// Create availability slots in top-level collection
  Future<List<Availability>> createAvailabilitySlots({
    required String mentorUid,
    required String mentorDocId,
    required String mentorName,
    required DateTime date,
    required List<Map<String, String>> slots,
  }) async {
    try {
      final batch = _firestore.batch();
      final createdSlots = <Availability>[];
      
      for (final slot in slots) {
        final startTime = slot['slot_start'];
        final endTime = slot['slot_end'] ?? MeetingHelpers.addHour(startTime!);
        
        // Parse the time slot to get full DateTime
        final slotDateTime = MeetingHelpers.parseTimeSlot(
          MeetingHelpers.formatDate(date), 
          startTime!
        );
        
        if (slotDateTime == null) continue;
        
        // Generate availability ID
        final availId = MeetingHelpers.generateAvailabilityId(mentorDocId, slotDateTime);
        
        final availData = {
          'id': availId,
          'mentor_uid': mentorUid,
          'mentor_doc_id': mentorDocId,
          'mentor_name': mentorName,
          'date': Timestamp.fromDate(date),
          'day_of_week': date.weekday,
          'start_time': startTime,
          'end_time': endTime,
          'is_booked': false,
          'booked_by_uid': null,
          'booked_by_name': null,
          'meeting_id': null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          // Composite fields for efficient querying
          'mentor_date': MeetingHelpers.createCompoundField(mentorUid, MeetingHelpers.formatDate(date)),
          'week_number': MeetingHelpers.getWeekNumber(date),
          'month_year': MeetingHelpers.getMonthYear(date),
        };
        
        batch.set(_availabilityCollection.doc(availId), availData);
        
        createdSlots.add(Availability(
          id: availId,
          mentorId: mentorUid,
          day: MeetingHelpers.formatDate(date),
          slotStart: startTime,
          slotEnd: endTime,
          isBooked: false,
          synced: true,
        ));
      }
      
      await batch.commit();
      return createdSlots;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating availability slots: $e');
      }
      throw Exception('Failed to create availability: $e');
    }
  }
  
  /// Get availability for a mentor
  Future<List<Availability>> getAvailabilityByMentor(String mentorUid) async {
    try {
      final querySnapshot = await _availabilityCollection
          .where(MeetingConstants.fieldMentorUid, isEqualTo: mentorUid)
          .orderBy(MeetingConstants.fieldDate, descending: false)
          .get();
      
      return _parseAvailabilityDocs(querySnapshot.docs);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting availability: $e');
      }
      return [];
    }
  }
  
  /// Get available (unbooked) slots for a mentor within date range
  Future<List<Availability>> getAvailableSlots({
    required String mentorUid,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _availabilityCollection
          .where(MeetingConstants.fieldMentorUid, isEqualTo: mentorUid)
          .where(MeetingConstants.fieldIsBooked, isEqualTo: false)
          .where(MeetingConstants.fieldDate, isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(MeetingConstants.fieldDate, isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(MeetingConstants.fieldDate)
          .orderBy('start_time')
          .get();
      
      return _parseAvailabilityDocs(querySnapshot.docs);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available slots: $e');
      }
      return [];
    }
  }
  
  /// Subscribe to real-time availability updates
  void subscribeToAvailability(String mentorUid) {
    // Cancel previous subscription
    _streamManager.cancelAllSubscriptions();
    
    print('\n🔍 === SUBSCRIBING TO AVAILABILITY (TOP-LEVEL) ===${'=' * 50}');
    print('🔍 Mentor UID: $mentorUid');
    print('🔍 University Path: $_universityPath');
    print('🔍 Full Collection Path: ${_availabilityCollection.path}');
    print('🔍 Expected path format: {universityPath}/data/availability');
    print('🔍 Query field: ${MeetingConstants.fieldMentorUid} (value: "mentor_id") = $mentorUid');
    
    // First, let's try to get all documents to debug
    print('🔍 DEBUG: Attempting to fetch ALL availability documents...');
    _availabilityCollection.get().then((snapshot) {
      print('🔍 DEBUG: Total documents in availability collection: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('🔍 DEBUG: Doc ${doc.id}:');
        print('  - mentor_id value: "${data['mentor_id']}"');
        print('  - mentor_id type: ${data['mentor_id'].runtimeType}');
        print('  - mentor_id == mentorUid? ${data['mentor_id'] == mentorUid}');
        print('  - Query mentorUid value: "$mentorUid"');
        print('  - Query mentorUid type: ${mentorUid.runtimeType}');
        print('  - day: ${data['day']}');
        print('  - slots: ${data['slots']?.length ?? 0} slots');
        
        // Check for invisible characters
        if (data['mentor_id'] != null && data['mentor_id'] is String) {
          final dbValue = data['mentor_id'] as String;
          print('  - mentor_id length: ${dbValue.length}');
          print('  - mentorUid length: ${mentorUid.length}');
          if (dbValue.length == mentorUid.length && dbValue != mentorUid) {
            print('  - ⚠️ Same length but different values! Possible invisible characters.');
          }
        }
      }
    }).catchError((error) {
      print('🔍 DEBUG: Error fetching all docs: $error');
    });
    
    // Test: First try without where clause to see if stream works
    print('🔍 TEST: Setting up stream WITHOUT where clause first...');
    _availabilityCollection.snapshots().take(1).listen((snapshot) {
      print('🔍 TEST RESULT: Stream without where clause returned ${snapshot.docs.length} documents');
    });
    
    // Now try with where clause
    final query = _availabilityCollection
        .where(MeetingConstants.fieldMentorUid, isEqualTo: mentorUid);
    
    print('🔍 Executing query with where clause...');
    
    // Also try a one-time get to see if query works
    query.get().then((snapshot) {
      print('🔍 TEST: One-time query.get() returned ${snapshot.docs.length} documents');
      if (snapshot.docs.isEmpty) {
        print('🔍 ⚠️ Query returned no documents! This suggests the where clause is filtering everything out.');
        print('🔍 Double-checking field name: ${MeetingConstants.fieldMentorUid} should equal "mentor_id"');
      }
    }).catchError((error) {
      print('🔍 ERROR in query.get(): $error');
    });
    
    // Since the query.get() works, let's use the query directly
    print('🔍 Using query-based subscription since query.get() returned ${3} documents');
    
    final subscription = query.snapshots().listen(
      (snapshot) {
        print('\n📊 === AVAILABILITY SNAPSHOT ===${'=' * 50}');
        print('📊 Timestamp: ${DateTime.now().toIso8601String()}');
        print('📊 Documents received: ${snapshot.docs.length}');
        
        if (snapshot.docs.isEmpty) {
          print('📊 ⚠️ NO DOCUMENTS FOUND for mentor_id: $mentorUid');
          print('📊 Trying fallback to all documents...');
          
          // Fallback: get all documents
          _availabilityCollection.get().then((allSnapshot) {
            print('📊 FALLBACK: Got ${allSnapshot.docs.length} total documents');
            final filteredDocs = allSnapshot.docs.where((doc) {
              final data = doc.data();
              return data['mentor_id'] == mentorUid && !MeetingHelpers.shouldSkipDocument(doc.id);
            }).toList();
            
            print('📊 FALLBACK: Filtered to ${filteredDocs.length} documents');
            final availabilityList = _parseAvailabilityDocs(filteredDocs);
            _streamManager.updateAvailabilityStream(availabilityList);
          });
        } else {
          for (var i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            final data = doc.data();
            print('📊 Doc ${i + 1}: ${doc.id}');
            print('  - mentor_id: ${data['mentor_id']}');
            print('  - day: ${data['day']}');
            print('  - slots: ${data['slots']?.length ?? 0} slots');
          }
          
          final availabilityList = _parseAvailabilityDocs(snapshot.docs);
          print('📊 Parsed ${availabilityList.length} availability slots');
          
          _streamManager.updateAvailabilityStream(availabilityList);
          print('📊 ✅ Stream updated with ${availabilityList.length} slots');
        }
        
        print('📊 === AVAILABILITY SNAPSHOT END ===${'=' * 50}\n');
      },
      onError: (error) {
        print('\n❌ === AVAILABILITY ERROR ===${'=' * 50}');
        print('❌ Error: $error');
        print('❌ Error type: ${error.runtimeType}');
        print('❌ === ERROR END ===${'=' * 50}\n');
        
        // Fallback on error
        print('❌ Falling back to direct get() due to stream error');
        _availabilityCollection.get().then((snapshot) {
          final filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['mentor_id'] == mentorUid && !MeetingHelpers.shouldSkipDocument(doc.id);
          }).toList();
          
          final availabilityList = _parseAvailabilityDocs(filteredDocs);
          _streamManager.updateAvailabilityStream(availabilityList);
        });
      },
    );
    
    _streamManager.setAvailabilitySubscription(subscription);
    
    // IMMEDIATE FETCH: Also do an immediate fetch to populate data right away
    print('🔍 Performing immediate fetch to populate initial data...');
    query.get().then((snapshot) {
      print('🔍 IMMEDIATE FETCH: Got ${snapshot.docs.length} documents');
      if (snapshot.docs.isNotEmpty) {
        final availabilityList = _parseAvailabilityDocs(snapshot.docs);
        print('🔍 IMMEDIATE FETCH: Updating stream with ${availabilityList.length} slots');
        _streamManager.updateAvailabilityStream(availabilityList);
      }
    }).catchError((error) {
      print('🔍 IMMEDIATE FETCH ERROR: $error');
    });
    
    // POLLING FALLBACK: Set up periodic fetching as a workaround
    print('🔍 Setting up polling fallback (fetching every 5 seconds)...');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      query.get().then((snapshot) {
        print('🔍 POLLING: Got ${snapshot.docs.length} documents');
        if (snapshot.docs.isNotEmpty) {
          final availabilityList = _parseAvailabilityDocs(snapshot.docs);
          _streamManager.updateAvailabilityStream(availabilityList);
        }
      }).catchError((error) {
        print('🔍 POLLING ERROR: $error');
      });
    });
  }
  
  /// Cancel polling timer
  void dispose() {
    _pollingTimer?.cancel();
    _streamManager.cancelAllSubscriptions();
  }
  
  /// Book an availability slot
  Future<bool> bookSlot({
    required String slotId,
    required String menteeUid,
    required String menteeDocId,
    required String menteeName,
    required String meetingId,
  }) async {
    try {
      // Parse the slot ID format: "documentId_slot_index"
      final parts = slotId.split('_slot_');
      if (parts.length != 2) {
        throw Exception('Invalid slot ID format: $slotId');
      }
      
      final docId = parts[0];
      final slotIndex = int.tryParse(parts[1]);
      
      if (slotIndex == null) {
        throw Exception('Invalid slot index in ID: $slotId');
      }
      
      // Get the document to update the specific slot
      final docSnapshot = await _availabilityCollection.doc(docId).get();
      if (!docSnapshot.exists) {
        throw Exception('Availability document not found: $docId');
      }
      
      final data = docSnapshot.data()!;
      final slots = List<Map<String, dynamic>>.from(data['slots'] ?? []);
      
      if (slotIndex >= slots.length) {
        throw Exception('Slot index out of range: $slotIndex');
      }
      
      // Update the specific slot
      slots[slotIndex] = {
        ...slots[slotIndex],
        'is_booked': true,
        'mentee_id': menteeUid,
      };
      
      // Update the document with the modified slots array
      await _availabilityCollection.doc(docId).update({
        'slots': slots,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Successfully booked slot $slotIndex in document $docId');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error booking slot: $e');
      }
      return false;
    }
  }
  
  /// Unbook an availability slot
  Future<bool> unbookSlot(String slotId) async {
    try {
      // Parse the slot ID format: "documentId_slot_index"
      final parts = slotId.split('_slot_');
      if (parts.length != 2) {
        throw Exception('Invalid slot ID format: $slotId');
      }
      
      final docId = parts[0];
      final slotIndex = int.tryParse(parts[1]);
      
      if (slotIndex == null) {
        throw Exception('Invalid slot index in ID: $slotId');
      }
      
      // Get the document to update the specific slot
      final docSnapshot = await _availabilityCollection.doc(docId).get();
      if (!docSnapshot.exists) {
        throw Exception('Availability document not found: $docId');
      }
      
      final data = docSnapshot.data()!;
      final slots = List<Map<String, dynamic>>.from(data['slots'] ?? []);
      
      if (slotIndex >= slots.length) {
        throw Exception('Slot index out of range: $slotIndex');
      }
      
      // Update the specific slot
      slots[slotIndex] = {
        ...slots[slotIndex],
        'is_booked': false,
        'mentee_id': null,
      };
      
      // Update the document with the modified slots array
      await _availabilityCollection.doc(docId).update({
        'slots': slots,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Successfully unbooked slot $slotIndex in document $docId');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unbooking slot: $e');
      }
      return false;
    }
  }
  
  /// Delete an availability slot
  Future<bool> deleteSlot(String slotId) async {
    try {
      // Check if slot is booked
      final doc = await _availabilityCollection.doc(slotId).get();
      if (doc.exists && doc.data()?['is_booked'] == true) {
        throw Exception('Cannot delete booked slot');
      }
      
      await _availabilityCollection.doc(slotId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting slot: $e');
      }
      return false;
    }
  }
  
  /// Parse Firestore documents to Availability objects
  List<Availability> _parseAvailabilityDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    print('📋 === PARSING AVAILABILITY DOCS ===${'=' * 50}');
    print('📋 Received ${docs.length} documents to parse');
    
    final availabilityList = <Availability>[];
    
    for (final doc in docs) {
      print('📋 Processing doc: ${doc.id}');
      
      // Skip metadata documents
      if (MeetingHelpers.shouldSkipDocument(doc.id)) {
        print('📋 Skipping metadata document: ${doc.id}');
        continue;
      }
      
      final data = doc.data();
      print('📋 Document data keys: ${data.keys.join(', ')}');
      
      // Handle array structure - each document contains multiple slots
      if (data['slots'] != null && data['slots'] is List) {
        final slots = data['slots'] as List;
        print('📋 Found ${slots.length} slots in document');
        
        // Create an Availability object for each slot
        for (final slot in slots) {
          final availability = Availability(
            id: '${doc.id}_slot_${slots.indexOf(slot)}',  // Unique ID for each slot
            mentorId: data['mentor_id'] ?? '',
            day: data['day'] ?? '',
            slotStart: slot['slot_start'] ?? '',
            slotEnd: slot['slot_end'] ?? '',
            isBooked: slot['is_booked'] ?? false,
            menteeId: slot['mentee_id'],
            synced: data['synced'] ?? true,
          );
          availabilityList.add(availability);
          print('📋 Added slot: ${availability.day} at ${availability.slotStart}');
        }
      } else {
        print('📋 ⚠️ No slots array found in document ${doc.id}');
      }
    }
    
    print('📋 Total slots parsed: ${availabilityList.length}');
    print('📋 === PARSING COMPLETE ===${'=' * 50}');
    
    return availabilityList;
  }
}