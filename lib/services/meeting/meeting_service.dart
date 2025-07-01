import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../cloud_function_service.dart';
import '../auth_service.dart';
import '../../models/availability.dart';
import '../../models/meeting.dart';
import 'repositories/meeting_repository.dart';
import 'repositories/availability_repository.dart';
import 'repositories/user_repository.dart';
import 'managers/stream_manager.dart';
import 'managers/cache_manager.dart';
import 'utils/meeting_constants.dart';

/// Main MeetingService that provides a unified interface for all meeting-related operations
/// This service uses a modular architecture with separate repositories and managers
class MeetingService {
  static final MeetingService _instance = MeetingService._internal();
  factory MeetingService() => _instance;
  MeetingService._internal();

  // Dependencies
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
  
  // Repositories
  MeetingRepository? _meetingRepository;
  AvailabilityRepository? _availabilityRepository;
  UserRepository? _userRepository;
  
  // Managers
  final MeetingStreamManager _streamManager = MeetingStreamManager();
  final MeetingCacheManager _cacheManager = MeetingCacheManager();
  
  String get _universityPath => _cloudFunctions.getCurrentUniversityPath();
  
  // Stream getters
  Stream<List<Availability>> get availabilityStream => _streamManager.availabilityStream;
  Stream<List<Meeting>> get meetingsStream => _streamManager.meetingsStream;

  // ========== INITIALIZATION ==========
  
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
    
    // Initialize repositories
    _meetingRepository = MeetingRepository(
      firestore: _firestore!,
      universityPath: _universityPath,
    );
    _availabilityRepository = AvailabilityRepository(
      firestore: _firestore!,
      universityPath: _universityPath,
    );
    _userRepository = UserRepository(
      firestore: _firestore!,
      universityPath: _universityPath,
    );
  }
  
  /// Ensure repositories are initialized
  void _ensureInitialized() {
    if (!_isFirestoreInitialized) {
      _initializeFirestore();
    }
  }

  // ========== AVAILABILITY OPERATIONS ==========
  
  /// Create availability slots (uses cloud function for now, will migrate to direct writes)
  Future<List<Availability>> createAvailability(List<Availability> slots) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      final day = slots.isNotEmpty ? slots.first.day : '';
      final slotsData = slots.map((slot) => {
        'slot_start': slot.slotStart,
        'slot_end': slot.slotEnd,
      }).toList();

      // Debug logging
      if (kDebugMode) {
        print('🔍 MeetingService.createAvailability DEBUG:');
        print('🔍 Current User UID: ${currentUser.uid}');
        print('🔍 Day: $day');
        print('🔍 Slots count: ${slotsData.length}');
      }

      // For now, use cloud function (will be replaced with direct repository call)
      final result = await _cloudFunctions.setMentorAvailability(
        universityPath: _universityPath,
        mentorId: currentUser.uid,
        day: day,
        slots: slotsData,
      );

      if (result['success'] == true) {
        return slots.map((slot) => slot.copyWith(
          synced: true,
        )).toList();
      } else {
        throw Exception(result['error'] ?? MeetingConstants.errorAvailabilityCreationFailed);
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
      // Use cloud function to get mentor availability
      final result = await _cloudFunctions.getMentorAvailability(
        universityPath: _universityPath,
        mentorId: mentorId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as List<dynamic>;
        
        // Convert the data to List<Availability>
        // The cloud function returns data with a 'slots' array, but our Availability model
        // represents individual slots. We need to flatten this structure.
        final List<Availability> availabilities = [];
        
        for (final item in data) {
          final Map<String, dynamic> availData = item as Map<String, dynamic>;
          final day = availData['day'] ?? '';
          final slots = availData['slots'] as List<dynamic>? ?? [];
          
          // If there are slots, create an Availability object for each slot
          if (slots.isNotEmpty) {
            for (final slot in slots) {
              availabilities.add(Availability(
                id: '${availData['id']}_${slot['slot_start']}', // Create unique ID
                mentorId: availData['mentor_id'] ?? mentorId,
                day: day,
                slotStart: slot['slot_start'] ?? '',
                slotEnd: slot['slot_end'],
                isBooked: slot['is_booked'] ?? false,
                menteeId: slot['booked_by_uid'],
                synced: availData['synced'] ?? true,
              ));
            }
          } else {
            // If no slots array, treat it as a single slot (backward compatibility)
            availabilities.add(Availability(
              id: availData['id'] ?? '',
              mentorId: availData['mentor_id'] ?? mentorId,
              day: day,
              slotStart: availData['slot_start'] ?? '',
              slotEnd: availData['slot_end'],
              isBooked: availData['is_booked'] ?? false,
              menteeId: availData['mentee_id'],
              synced: availData['synced'] ?? true,
            ));
          }
        }
        
        return availabilities;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'Failed to get availability');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting availability: $e');
      }
      return [];
    }
  }

  /// Subscribe to real-time availability updates
  void subscribeToAvailability(String mentorId) {
    _ensureInitialized();
    _availabilityRepository!.subscribeToAvailability(mentorId);
  }

  /// Remove availability slot
  Future<bool> removeAvailabilitySlot(String slotId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      // Use cloud function to remove availability slot
      final result = await _cloudFunctions.removeAvailabilitySlot(
        universityPath: _universityPath,
        slotId: slotId,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing availability slot: $e');
      }
      return false;
    }
  }

  // ========== MEETING OPERATIONS ==========
  
  /// Create a new meeting
  Future<Meeting> createMeeting(Meeting meeting) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      // Parse date and time from the meeting startTime
      final startDateTime = DateTime.parse(meeting.startTime);
      final date = '${startDateTime.year}-${startDateTime.month.toString().padLeft(2, '0')}-${startDateTime.day.toString().padLeft(2, '0')}';
      final startTime = '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
      
      String? endTime;
      if (meeting.endTime != null) {
        final endDateTime = DateTime.parse(meeting.endTime!);
        endTime = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
      }

      // Use cloud function to create meeting
      final result = await _cloudFunctions.createMeeting(
        universityPath: _universityPath,
        mentorId: meeting.mentorId,
        menteeId: meeting.menteeId,
        date: date,
        startTime: startTime,
        endTime: endTime ?? '',
        topic: meeting.topic,
        location: meeting.location,
        availabilityId: meeting.availabilityId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        
        // Convert cloud function response to Meeting object
        return Meeting(
          id: data['id'] ?? '',
          mentorId: data['mentor_id'] ?? meeting.mentorId,
          menteeId: data['mentee_id'] ?? meeting.menteeId,
          startTime: data['start_time'] ?? meeting.startTime,
          endTime: data['end_time'],
          topic: data['topic'] ?? meeting.topic,
          location: data['location'] ?? meeting.location,
          status: data['status'] ?? 'pending',
          availabilityId: data['availability_id'],
          synced: true,
        );
      } else {
        throw Exception(result['error'] ?? result['message'] ?? MeetingConstants.errorMeetingCreationFailed);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating meeting: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to real-time meeting updates
  void subscribeToMeetings(String userId) {
    _ensureInitialized();
    _meetingRepository!.subscribeToMeetings(userId);
  }

  /// Update meeting
  Future<int> updateMeeting(Meeting meeting) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      // Parse date and time from the meeting startTime
      final startDateTime = DateTime.parse(meeting.startTime);
      final date = '${startDateTime.year}-${startDateTime.month.toString().padLeft(2, '0')}-${startDateTime.day.toString().padLeft(2, '0')}';
      final startTime = '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
      
      String? endTime;
      if (meeting.endTime != null) {
        final endDateTime = DateTime.parse(meeting.endTime!);
        endTime = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
      }

      // Use cloud function to update meeting
      final result = await _cloudFunctions.updateMeeting(
        universityPath: _universityPath,
        meetingId: meeting.id,
        date: date,
        startTime: startTime,
        endTime: endTime,
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
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      // Use cloud function to cancel meeting
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
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      // Use cloud function to update meeting status to accepted
      final result = await _cloudFunctions.updateMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
        status: MeetingConstants.statusAccepted,
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
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      // Use cloud function to update meeting status to rejected
      // Note: The cloud function updateMeeting doesn't support reason field,
      // so we'll need to use cancelMeeting which does support reason
      final result = await _cloudFunctions.cancelMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
        reason: reason ?? 'Meeting rejected by mentor',
      );
      
      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting meeting: $e');
      }
      return false;
    }
  }

  /// Delete/Clear a meeting from the database
  Future<bool> deleteMeeting(String meetingId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      // Ensure repositories are initialized
      _ensureInitialized();
      
      // Use the repository to actually delete the meeting
      await _meetingRepository!.deleteMeeting(meetingId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting meeting: $e');
      }
      return false;
    }
  }

  /// Hide a meeting from the current user's view
  Future<bool> hideMeeting(String meetingId) async {
    try {
      if (kDebugMode) {
        print('🔍 MeetingService.hideMeeting: Starting to hide meeting $meetingId');
      }
      
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('🔍 MeetingService.hideMeeting: No current user, returning false');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('🔍 MeetingService.hideMeeting: Current user UID: ${currentUser.uid}');
        print('🔍 MeetingService.hideMeeting: University path: $_universityPath');
      }
      
      final result = await _cloudFunctions.hideMeeting(
        universityPath: _universityPath,
        meetingId: meetingId,
      );
      
      if (kDebugMode) {
        print('🔍 MeetingService.hideMeeting: Cloud function result: $result');
      }
      
      final success = result['success'] == true;
      if (kDebugMode) {
        print('🔍 MeetingService.hideMeeting: Returning success: $success');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('🔍 MeetingService.hideMeeting: Error occurred: $e');
        print('🔍 MeetingService.hideMeeting: Error type: ${e.runtimeType}');
      }
      return false;
    }
  }

  /// Request a meeting (mentee only)
  Future<Meeting?> requestMeeting({
    required String mentorId,
    required String date,
    required String startTime,
    String? endTime,
    required String topic,
    String? location,
    String? availabilityId,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      // If availabilityId is provided, use createMeeting (which supports availability booking)
      // Otherwise use requestMeeting for custom time requests
      if (availabilityId != null && availabilityId.isNotEmpty) {
        // Create a meeting object and use createMeeting
        final meeting = Meeting(
          id: '', // Will be generated
          mentorId: mentorId,
          menteeId: currentUser.uid,
          startTime: '${date}T${startTime}:00',
          endTime: endTime != null ? '${date}T${endTime}:00' : null,
          topic: topic ?? '',
          location: location ?? '',
          status: MeetingConstants.statusPending,
          availabilityId: availabilityId,
          synced: false,
        );
        
        return await createMeeting(meeting);
      } else {
        // Use requestMeeting for custom time requests (no availability slot)
        final result = await _cloudFunctions.requestMeeting(
          universityPath: _universityPath,
          mentorId: mentorId,
          menteeId: currentUser.uid,
          date: date,
          startTime: startTime,
          endTime: endTime ?? '',
          topic: topic,
          location: location,
        );

        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;
          
          // Convert cloud function response to Meeting object
          return Meeting(
            id: data['id'] ?? '',
            mentorId: data['mentor_id'] ?? mentorId,
            menteeId: data['mentee_id'] ?? currentUser.uid,
            startTime: data['start_time'] ?? '${date}T${startTime}:00',
            endTime: data['end_time'] ?? (endTime != null ? '${date}T${endTime}:00' : null),
            topic: data['topic'] ?? topic,
            location: data['location'] ?? location,
            status: data['status'] ?? MeetingConstants.statusPending,
            availabilityId: null, // No availability ID for custom requests
            synced: true,
          );
        } else {
          throw Exception(result['error'] ?? result['message'] ?? 'Failed to request meeting');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting meeting: $e');
      }
      return null;
    }
  }

  // ========== UTILITY METHODS ==========
  
  /// Get user document ID from Firebase UID
  Future<String?> getUserDocIdFromUid(String uid) async {
    _ensureInitialized();
    return await _userRepository!.getUserDocIdFromUid(uid);
  }
  
  /// Get user data from Firebase UID
  Future<Map<String, dynamic>?> getUserDataFromUid(String uid) async {
    _ensureInitialized();
    return await _userRepository!.getUserDataFromUid(uid);
  }
  
  /// Clear all caches
  void clearCaches() {
    _cacheManager.clearAllCaches();
  }
  
  /// Get debug statistics
  Map<String, dynamic> getDebugStats() {
    return {
      'cache': _cacheManager.getCacheStats(),
      'streams': _streamManager.getStreamStats(),
      'initialized': _isFirestoreInitialized,
      'universityPath': _universityPath,
    };
  }

  /// Clean up resources
  void dispose() {
    _streamManager.dispose();
    _cacheManager.clearAllCaches();
  }
}