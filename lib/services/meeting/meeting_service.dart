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
    _ensureInitialized();
    return await _availabilityRepository!.getAvailabilityByMentor(mentorId);
  }

  /// Subscribe to real-time availability updates
  void subscribeToAvailability(String mentorId) {
    _ensureInitialized();
    _availabilityRepository!.subscribeToAvailability(mentorId);
  }

  /// Remove availability slot
  Future<bool> removeAvailabilitySlot(String slotId) async {
    _ensureInitialized();
    return await _availabilityRepository!.deleteSlot(slotId);
  }

  // ========== MEETING OPERATIONS ==========
  
  /// Create a new meeting
  Future<Meeting> createMeeting(Meeting meeting) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(MeetingConstants.errorUserNotAuthenticated);
      }

      _ensureInitialized();
      
      // Get user data for both mentor and mentee
      final usersData = await _userRepository!.getUsersDataByUids([
        meeting.mentorId,
        meeting.menteeId,
      ]);
      
      final mentorData = usersData[meeting.mentorId];
      final menteeData = usersData[meeting.menteeId];
      
      if (mentorData == null || menteeData == null) {
        throw Exception(MeetingConstants.errorUserDocumentNotFound);
      }

      // Create meeting using repository
      final createdMeeting = await _meetingRepository!.createMeeting(
        mentorUid: meeting.mentorId,
        menteeUid: meeting.menteeId,
        mentorDocId: mentorData['id'],
        menteeDocId: menteeData['id'],
        mentorName: mentorData['name'] ?? '',
        menteeName: menteeData['name'] ?? '',
        startTime: DateTime.parse(meeting.startTime),
        endTime: meeting.endTime != null ? DateTime.parse(meeting.endTime!) : null,
        topic: meeting.topic,
        location: meeting.location,
        availabilitySlotId: meeting.availabilityId,
        status: meeting.status,
      );
      
      // If an availability slot was specified, book it
      if (meeting.availabilityId != null && meeting.availabilityId!.isNotEmpty) {
        print('Booking availability slot: ${meeting.availabilityId}');
        final bookingSuccess = await _availabilityRepository!.bookSlot(
          slotId: meeting.availabilityId!,
          menteeUid: meeting.menteeId,
          menteeDocId: menteeData['id'],
          menteeName: menteeData['name'] ?? '',
          meetingId: createdMeeting.id,
        );
        
        if (!bookingSuccess) {
          print('Warning: Failed to book availability slot');
        }
      }
      
      return createdMeeting;
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
    _ensureInitialized();
    
    final success = await _meetingRepository!.updateMeeting(
      meetingId: meeting.id,
      startTime: DateTime.parse(meeting.startTime),
      endTime: meeting.endTime != null ? DateTime.parse(meeting.endTime!) : null,
      topic: meeting.topic,
      location: meeting.location,
    );
    
    return success ? 1 : 0;
  }

  /// Cancel meeting
  Future<bool> cancelMeeting(String meetingId, {String? reason}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;
      
      _ensureInitialized();
      
      return await _meetingRepository!.updateMeetingStatus(
        meetingId: meetingId,
        status: MeetingConstants.statusCancelled,
        updatedBy: currentUser.uid,
        reason: reason,
      );
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
      
      _ensureInitialized();
      
      return await _meetingRepository!.updateMeetingStatus(
        meetingId: meetingId,
        status: MeetingConstants.statusAccepted,
        updatedBy: currentUser.uid,
      );
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
      
      _ensureInitialized();
      
      return await _meetingRepository!.updateMeetingStatus(
        meetingId: meetingId,
        status: MeetingConstants.statusRejected,
        updatedBy: currentUser.uid,
        reason: reason,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting meeting: $e');
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

      final meeting = Meeting(
        id: '', // Will be generated
        mentorId: mentorId,
        menteeId: currentUser.uid,
        startTime: '${date}T${startTime}:00',
        endTime: endTime != null ? '${date}T${endTime}:00' : null,
        topic: topic,
        location: location,
        status: MeetingConstants.statusPending,
        availabilityId: availabilityId,
        synced: false,
      );

      return await createMeeting(meeting);
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