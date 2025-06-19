import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'cloud_function_service.dart';
import 'auth_service.dart';
import '../models/availability.dart';
import '../models/meeting.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';

class MeetingService {
  static final MeetingService _instance = MeetingService._internal();
  factory MeetingService() => _instance;
  MeetingService._internal();

  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
  final _uuid = const Uuid();
  
  String get _universityPath => _cloudFunctions.getCurrentUniversityPath();

  // Stream controllers for real-time updates
  StreamController<List<Availability>>? _availabilityStreamController;
  StreamController<List<Meeting>>? _meetingsStreamController;
  
  Stream<List<Availability>> get availabilityStream {
    _availabilityStreamController ??= StreamController<List<Availability>>.broadcast();
    return _availabilityStreamController!.stream;
  }
  
  Stream<List<Meeting>> get meetingsStream {
    _meetingsStreamController ??= StreamController<List<Meeting>>.broadcast();
    return _meetingsStreamController!.stream;
  }

  void _initializeFirestore() {
    if (_isFirestoreInitialized) {
      return;
    }
    
    _firestore = FirebaseFirestore.instance;
    
    // Check if we should use emulator
    bool shouldUseEmulator = false;
    
    // Check compile-time environment variable
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    if (useEmulator == 'true') {
      shouldUseEmulator = true;
    }
    
    // Check if running in debug mode on web with localhost
    if (kDebugMode) {
      if (kIsWeb) {
        final uri = Uri.base;
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          shouldUseEmulator = true;
        }
      } else {
        // For mobile/desktop in debug mode
        shouldUseEmulator = true;
      }
    }
    
    // Never use emulator in release mode
    if (kReleaseMode) {
      shouldUseEmulator = false;
    }
    
    if (shouldUseEmulator) {
      try {
        _firestore!.useFirestoreEmulator('localhost', 8080);
        print('🔥 Meeting service connected to Firestore emulator at localhost:8080');
      } catch (e) {
        // Already connected or emulator not available
        print('⚠️ Firestore emulator connection failed: $e');
      }
    } else {
      print('🔥 Meeting service using production Firestore');
    }
    
    _isFirestoreInitialized = true;
  }

  // ========== AVAILABILITY OPERATIONS ==========
  
  /// Create availability slots (batch operation for multiple slots)
  Future<List<Availability>> createAvailability(List<Availability> slots) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final day = slots.isNotEmpty ? slots.first.day : '';
      final slotsData = slots.map((slot) => {
        'slot_start': slot.slotStart,
        'slot_end': slot.slotEnd,
      }).toList();

      // Debug logging
      print('🔍 MeetingService.createAvailability DEBUG:');
      print('🔍 Current User UID: ${currentUser.uid}');
      print('🔍 Current User Email: ${currentUser.email}');
      print('🔍 University Path: $_universityPath');
      print('🔍 Day: $day');
      print('🔍 Slots count: ${slotsData.length}');

      final result = await _cloudFunctions.setMentorAvailability(
        universityPath: _universityPath,
        mentorId: currentUser.uid,
        day: day,
        slots: slotsData,
      );

      if (result['success'] == true) {
        // Return the created slots with generated IDs
        return slots.map((slot) => slot.copyWith(
          id: _uuid.v4(),
          synced: true,
        )).toList();
      } else {
        throw Exception(result['error'] ?? 'Failed to create availability');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating availability: $e');
      }
      rethrow;
    }
  }

  /// Get availability by mentor
  Future<List<Availability>> getAvailabilityByMentor(String mentorId) async {
    try {
      _initializeFirestore();
      
      final result = await _cloudFunctions.getMentorAvailability(
        universityPath: _universityPath,
        mentorId: mentorId,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> availabilityDocs = result['data'];
        final List<Availability> allSlots = [];
        
        // Each document now contains multiple slots for a day
        for (final doc in availabilityDocs) {
          final String docId = doc['id'];
          
          // Skip metadata documents
          if (docId == '_metadata' || docId.startsWith('_')) {
            continue;
          }
          
          final String day = doc['day'];
          final String mentorId = doc['mentor_id'];
          final List<dynamic> slots = doc['slots'] ?? [];
          
          // Convert each slot in the array to an Availability object
          for (int i = 0; i < slots.length; i++) {
            final slot = slots[i];
            allSlots.add(Availability(
              id: '${docId}_slot_$i', // Create unique ID for each slot
              mentorId: mentorId,
              day: day,
              slotStart: slot['slot_start'],
              slotEnd: slot['slot_end'],
              isBooked: slot['is_booked'] ?? false,
              menteeId: slot['mentee_id'],
              synced: true,
            ));
          }
        }
        
        return allSlots;
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting availability: $e');
      }
      return [];
    }
  }

  /// Subscribe to real-time availability updates
  StreamSubscription<QuerySnapshot>? _availabilitySubscription;
  
  void subscribeToAvailability(String mentorId) {
    _initializeFirestore();
    
    _availabilitySubscription?.cancel();
    
    // First try to get the user document ID from the mentorId (Firebase UID)
    final usersCollection = _firestore!
        .collection(_universityPath)
        .doc('data')
        .collection('users');
    
    // Find the user document by Firebase UID
    usersCollection
        .where('firebase_uid', isEqualTo: mentorId)
        .limit(1)
        .get()
        .then((userQuery) {
      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id;
        
        print('DEBUG: Found user document ID: $userDocId for Firebase UID: $mentorId');
        
        // Subscribe to the user's availability subcollection
        final collection = usersCollection
            .doc(userDocId)
            .collection('availability');
        
        _availabilitySubscription = collection.snapshots().listen((snapshot) {
          final List<Availability> allSlots = [];
          
          print('DEBUG: Availability snapshot received with ${snapshot.docs.length} documents');
          
          // Each document now contains multiple slots for a day
          for (final doc in snapshot.docs) {
            // Skip metadata documents
            if (doc.id == '_metadata' || doc.id.startsWith('_')) {
              continue;
            }
            
            final data = doc.data();
            final String day = data['day'] ?? '';
            final String mentorIdFromDoc = data['mentor_id'] ?? '';
            final String docId = doc.id;
            final List<dynamic> slots = data['slots'] ?? [];
            
            print('DEBUG: Processing availability doc $docId with ${slots.length} slots');
            
            // Convert each slot in the array to an Availability object
            for (int i = 0; i < slots.length; i++) {
              final slot = slots[i];
              allSlots.add(Availability(
                id: '${docId}_slot_$i',
                mentorId: mentorIdFromDoc,
                day: day,
                slotStart: slot['slot_start'] ?? '',
                slotEnd: slot['slot_end'],
                isBooked: slot['is_booked'] ?? false,
                menteeId: slot['mentee_id'],
                synced: true,
              ));
            }
          }
          
          print('DEBUG: Total availability slots after processing: ${allSlots.length}');
          if (_availabilityStreamController != null && !_availabilityStreamController!.isClosed) {
            _availabilityStreamController!.add(allSlots);
          }
        });
      } else {
        print('DEBUG: No user document found for Firebase UID: $mentorId');
        // If no user doc found, send empty list
        if (_availabilityStreamController != null && !_availabilityStreamController!.isClosed) {
          _availabilityStreamController!.add([]);
        }
      }
    }).catchError((error) {
      print('ERROR: Failed to get user document: $error');
      if (_availabilityStreamController != null && !_availabilityStreamController!.isClosed) {
        _availabilityStreamController!.add([]);
      }
    });
  }

  /// Remove specific availability slot
  Future<bool> removeAvailabilitySlot(String mentorId, String day, String slotStart) async {
    try {
      final result = await _cloudFunctions.removeAvailabilitySlot(
        universityPath: _universityPath,
        mentorId: mentorId,
        day: day,
        slotStart: slotStart,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing availability slot: $e');
      }
      return false;
    }
  }

  /// Update availability
  Future<int> updateAvailability(Availability availability) async {
    try {
      // For now, we don't have a direct update function
      // This would typically be handled by booking/unbooking
      if (kDebugMode) {
        print('Update availability not implemented in Firebase yet');
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating availability: $e');
      }
      return 0;
    }
  }

  /// Get available slots for booking (unbooked slots only)
  Future<List<Availability>> getAvailableSlots(String mentorId, {String? startDate, String? endDate}) async {
    try {
      final result = await _cloudFunctions.getAvailableSlots(
        universityPath: _universityPath,
        mentorId: mentorId,
        day: startDate,  // Using startDate as day parameter
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> availabilityDocs = result['data'];
        final List<Availability> availableSlots = [];
        
        // Each document contains multiple slots for a day
        for (final doc in availabilityDocs) {
          final String day = doc['day'];
          final String mentorId = doc['mentor_id']; 
          final String docId = doc['id'];
          final List<dynamic> slots = doc['slots'] ?? [];
          
          // Only include unbooked slots
          for (int i = 0; i < slots.length; i++) {
            final slot = slots[i];
            if (slot['is_booked'] != true) {
              availableSlots.add(Availability(
                id: '${docId}_slot_$i',
                mentorId: mentorId,
                day: day,
                slotStart: slot['slot_start'],
                slotEnd: slot['slot_end'],
                isBooked: false,
                synced: true,
              ));
            }
          }
        }
        
        return availableSlots;
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available slots: $e');
      }
      return [];
    }
  }

  // ========== MEETING OPERATIONS ==========

  /// Create a new meeting
  Future<Meeting> createMeeting(Meeting meeting) async {
    try {
      final result = await _cloudFunctions.createMeeting(
        universityPath: _universityPath,
        mentorId: meeting.mentorId,
        menteeId: meeting.menteeId,
        date: meeting.startTime.split('T')[0],  // Extract date from ISO string
        startTime: meeting.startTime,
        endTime: meeting.endTime ?? meeting.startTime,  // Use startTime if endTime is null
        topic: meeting.topic,
        location: meeting.location,
        availabilityId: meeting.availabilityId,
      );

      if (result['success'] == true && result['data'] != null) {
        return meeting.copyWith(
          id: result['data']['id'],
          synced: true,
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to create meeting');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating meeting: $e');
      }
      rethrow;
    }
  }

  /// Get meetings by mentee
  Future<List<Meeting>> getMeetingsByMentee(String menteeId) async {
    try {
      _initializeFirestore();
      
      final snapshot = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('mentee_id', isEqualTo: menteeId)
          .orderBy('start_time', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Meeting(
          id: doc.id,
          mentorId: data['mentor_id'],
          menteeId: data['mentee_id'],
          startTime: data['start_time'],
          endTime: data['end_time'],
          topic: data['topic'],
          location: data['location'],
          status: data['status'] ?? 'pending',
          availabilityId: data['availability_id'],
          synced: true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings by mentee: $e');
      }
      return [];
    }
  }

  /// Get meetings by mentor
  Future<List<Meeting>> getMeetingsByMentor(String mentorId) async {
    try {
      _initializeFirestore();
      
      final snapshot = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('mentor_id', isEqualTo: mentorId)
          .orderBy('start_time', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Meeting(
          id: doc.id,
          mentorId: data['mentor_id'],
          menteeId: data['mentee_id'],
          startTime: data['start_time'],
          endTime: data['end_time'],
          topic: data['topic'],
          location: data['location'],
          status: data['status'] ?? 'pending',
          availabilityId: data['availability_id'],
          synced: true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings by mentor: $e');
      }
      return [];
    }
  }

  /// Subscribe to real-time meeting updates
  /// TODO: Optimize with date-based filtering to reduce reads:
  /// - Add startDate/endDate parameters
  /// - Query meetings within visible calendar range only
  /// - Example: .where('start_time', isGreaterThan: startDate).where('start_time', isLessThan: endDate)
  StreamSubscription<QuerySnapshot>? _meetingsSubscription;
  
  void subscribeToMeetings(String userId, bool isMentor) {
    print('\n🔍 === SUBSCRIBE TO MEETINGS START ===${'=' * 50}');
    print('🔍 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🔍 User ID (Firebase UID): $userId');
    print('🔍 Is Mentor: $isMentor');
    print('🔍 University Path: $_universityPath');
    
    _initializeFirestore();
    
    print('🔍 Stream Controller State:');
    print('  - Controller exists: ${_meetingsStreamController != null}');
    print('  - Controller closed: ${_meetingsStreamController?.isClosed ?? 'null'}');
    
    _meetingsSubscription?.cancel();
    print('🔍 Previous subscription cancelled');
    
    // First try to get the user document ID from the userId (Firebase UID)
    final usersCollection = _firestore!
        .collection(_universityPath)
        .doc('data')
        .collection('users');
    
    final fullPath = '${_universityPath}/data/users';
    print('🔍 Users collection path: $fullPath');
    print('🔍 Searching for user with firebase_uid: $userId');
    
    // Find the user document by Firebase UID
    usersCollection
        .where('firebase_uid', isEqualTo: userId)
        .limit(1)
        .get()
        .then((userQuery) {
      print('\n🔍 User query completed:');
      print('  - Documents found: ${userQuery.docs.length}');
      print('  - Query metadata: ${userQuery.metadata.isFromCache ? "FROM CACHE" : "FROM SERVER"}');
      
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        final userDocId = userDoc.id;
        final userData = userDoc.data();
        
        print('\n✅ Found user document:');
        print('  - Document ID: $userDocId');
        print('  - User name: ${userData['name'] ?? 'Unknown'}');
        print('  - User type: ${userData['userType'] ?? 'Unknown'}');
        print('  - Firebase UID in doc: ${userData['firebase_uid'] ?? 'Not set'}');
        
        final meetingsPath = '${fullPath}/$userDocId/meetings';
        print('\n🔍 Subscribing to meetings at path: $meetingsPath');
        
        // Subscribe to the user's meetings subcollection
        final collection = usersCollection
            .doc(userDocId)
            .collection('meetings');
        
        _meetingsSubscription = collection.snapshots().listen((snapshot) {
          print('\n📊 === MEETINGS SNAPSHOT UPDATE ===${'=' * 50}');
          print('📊 Timestamp: ${DateTime.now().toIso8601String()}');
          print('📊 Documents count: ${snapshot.docs.length}');
          print('📊 From cache: ${snapshot.metadata.isFromCache}');
          
          if (snapshot.docs.isEmpty) {
            print('📊 ⚠️ No meetings found in subcollection');
          }
          
          final meetings = snapshot.docs
              .where((doc) => !doc.id.startsWith('_')) // Filter out metadata documents
              .map((doc) {
            final data = doc.data();
            print('\n📄 Meeting document:');
            print('  - Doc ID: ${doc.id}');
            print('  - Exists: ${doc.exists}');
            print('  - Data fields: ${data.keys.join(', ')}');
            print('  - Raw data: $data');
            
            // Validate required fields
            final missingFields = <String>[];
            if (data['mentor_id'] == null) missingFields.add('mentor_id');
            if (data['mentee_id'] == null) missingFields.add('mentee_id');
            if (data['start_time'] == null) missingFields.add('start_time');
            if (data['topic'] == null) missingFields.add('topic');
            
            if (missingFields.isNotEmpty) {
              print('  - ⚠️ Missing fields: ${missingFields.join(', ')}');
            }
            
            return Meeting(
              id: doc.id,
              mentorId: data['mentor_id'] ?? '',
              menteeId: data['mentee_id'] ?? '',
              startTime: data['start_time'] ?? '',
              endTime: data['end_time'],
              topic: data['topic'],
              location: data['location'],
              status: data['status'] ?? 'pending',
              availabilityId: data['availability_id'],
              synced: true,
            );
          }).toList();
          
          print('\n📊 Processed ${meetings.length} meetings:');
          for (var i = 0; i < meetings.length; i++) {
            final meeting = meetings[i];
            print('  ${i + 1}. Meeting ${meeting.id}:');
            print('     - Topic: "${meeting.topic}"');
            print('     - Start: ${meeting.startTime}');
            print('     - Status: ${meeting.status}');
            print('     - Mentor ID: ${meeting.mentorId}');
            print('     - Mentee ID: ${meeting.menteeId}');
          }
          
          print('\n📊 Stream controller update:');
          print('  - Controller exists: ${_meetingsStreamController != null}');
          print('  - Controller closed: ${_meetingsStreamController?.isClosed ?? 'null'}');
          
          if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
            _meetingsStreamController!.add(meetings);
            print('  - ✅ Meetings added to stream');
          } else {
            print('  - ❌ Stream controller not available!');
          }
          print('📊 === SNAPSHOT UPDATE END ===${'=' * 50}\n');
        }, onError: (error) {
          print('\n❌ ERROR: Meeting subscription error:');
          print('  - Error type: ${error.runtimeType}');
          print('  - Error message: $error');
          print('  - Stack trace: ${StackTrace.current}');
          
          if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
            _meetingsStreamController!.add([]);
            print('  - Empty list sent to stream');
          }
        });
        
        print('🔍 Subscription setup complete');
      } else {
        print('\n⚠️ No user document found for Firebase UID: $userId');
        print('  - This means the user document is missing the firebase_uid field');
        print('  - Or the user document doesn\'t exist');
        
        // If no user doc found, send empty list
        if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
          _meetingsStreamController!.add([]);
          print('  - Empty list sent to stream');
        }
      }
    }).catchError((error) {
      print('\n❌ ERROR: Failed to get user document:');
      print('  - Error type: ${error.runtimeType}');
      print('  - Error message: $error');
      print('  - This might be a permissions issue');
      
      if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
        _meetingsStreamController!.add([]);
        print('  - Empty list sent to stream');
      }
    });
    
    print('🔍 === SUBSCRIBE TO MEETINGS END ===${'=' * 50}\n');
  }

  /// Update meeting
  Future<int> updateMeeting(Meeting meeting) async {
    try {
      final result = await _cloudFunctions.updateMeeting(
        universityPath: _universityPath,
        meetingId: meeting.id,
        date: meeting.startTime.split('T')[0],  // Extract date from ISO string
        startTime: meeting.startTime,
        endTime: meeting.endTime,
        topic: meeting.topic,
        location: meeting.location,
        status: meeting.status,
      );

      return result['success'] == true ? 1 : 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating meeting: $e');
      }
      return 0;
    }
  }

  /// Cancel meeting
  Future<bool> cancelMeeting(String meetingId, {String? reason}) async {
    try {
      final result = await _cloudFunctions.cancelMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
        reason: reason,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling meeting: $e');
      }
      return false;
    }
  }

  /// Accept meeting request (mentor only)
  Future<bool> acceptMeeting(String meetingId) async {
    try {
      final result = await _cloudFunctions.acceptMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting meeting: $e');
      }
      return false;
    }
  }

  /// Reject meeting request (mentor only)
  Future<bool> rejectMeeting(String meetingId, {String? reason}) async {
    try {
      final result = await _cloudFunctions.rejectMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
        reason: reason,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting meeting: $e');
      }
      return false;
    }
  }

  /// Request custom meeting time (mentee only)
  Future<Meeting> requestCustomMeeting({
    required String mentorId,
    required String menteeId,
    required String startTime,
    String? endTime,
    String? topic,
    String? location,
  }) async {
    try {
      final result = await _cloudFunctions.requestMeeting(
        universityPath: _universityPath,
        mentorId: mentorId,
        menteeId: menteeId,
        date: startTime.split('T')[0],  // Extract date from ISO string
        startTime: startTime,
        endTime: endTime ?? startTime,  // Use startTime if endTime not provided
        topic: topic,
        location: location,
      );

      if (result['success'] == true && result['data'] != null) {
        return Meeting(
          id: result['data']['id'],
          mentorId: mentorId,
          menteeId: menteeId,
          startTime: startTime,
          endTime: endTime,
          topic: topic ?? 'Custom time request',
          location: location,
          status: 'pending',
          synced: true,
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to request meeting');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting custom meeting: $e');
      }
      rethrow;
    }
  }

  /// Book an available slot
  Future<Meeting> bookAvailabilitySlot({
    required String availabilityId,
    required Availability slot,
    required String menteeId,
    String? topic,
    String? location,
  }) async {
    try {
      // Create meeting with the availability ID
      final meeting = Meeting(
        id: _uuid.v4(),
        mentorId: slot.mentorId,
        menteeId: menteeId,
        startTime: '${slot.day} ${slot.slotStart}',
        endTime: slot.slotEnd != null ? '${slot.day} ${slot.slotEnd}' : null,
        topic: topic,
        location: location,
        status: 'pending',
        availabilityId: availabilityId,
      );

      return await createMeeting(meeting);
    } catch (e) {
      if (kDebugMode) {
        print('Error booking availability slot: $e');
      }
      rethrow;
    }
  }

  /// Free up an availability slot (unbook)
  Future<bool> unbookAvailabilitySlot(String availabilityId) async {
    try {
      // This happens automatically when a meeting is cancelled
      // through the cancelMeeting function
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unbooking availability slot: $e');
      }
      return false;
    }
  }

  /// Get meetings by mentorship (between specific mentor and mentee)
  Future<List<Meeting>> getMeetingsByMentorship(String mentorId, String menteeId) async {
    try {
      _initializeFirestore();
      
      final snapshot = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('mentor_id', isEqualTo: mentorId)
          .where('mentee_id', isEqualTo: menteeId)
          .orderBy('start_time', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Meeting(
          id: doc.id,
          mentorId: data['mentor_id'],
          menteeId: data['mentee_id'],
          startTime: data['start_time'],
          endTime: data['end_time'],
          topic: data['topic'],
          location: data['location'],
          status: data['status'] ?? 'pending',
          availabilityId: data['availability_id'],
          synced: true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings by mentorship: $e');
      }
      return [];
    }
  }

  /// Get meetings count
  Future<int> getMeetingsCount() async {
    try {
      _initializeFirestore();
      
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;
      
      // For now, return count based on current user's meetings
      final meetings = await getMeetingsByMentor(currentUser.uid);
      return meetings.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meetings count: $e');
      }
      return 0;
    }
  }

  /// Get availability count
  Future<int> getAvailabilityCount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;
      
      final availability = await getAvailabilityByMentor(currentUser.uid);
      return availability.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting availability count: $e');
      }
      return 0;
    }
  }

  /// Clean up subscriptions
  void dispose() {
    _availabilitySubscription?.cancel();
    _meetingsSubscription?.cancel();
    _availabilityStreamController?.close();
    _meetingsStreamController?.close();
    _availabilityStreamController = null;
    _meetingsStreamController = null;
  }
}