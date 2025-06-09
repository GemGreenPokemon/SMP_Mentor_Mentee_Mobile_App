import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionService {
  // Singleton pattern setup
  static final CloudFunctionService _instance = CloudFunctionService._internal();
  factory CloudFunctionService() => _instance;

  late final FirebaseFunctions _functions;
  
  // Initialize with proper configuration
  CloudFunctionService._internal() {
    _functions = FirebaseFunctions.instance;
    
    // Use local emulator when USE_EMULATOR environment variable is set
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    if (useEmulator == 'true') {
      _functions.useFunctionsEmulator('127.0.0.1', 5001);
      print('Using local Firebase Functions emulator');
    } else {
      print('Using production Firebase Functions');
    }
  }

  // --- University Management Functions ---

  /// Initialize a new university database structure
  Future<Map<String, dynamic>> initializeUniversity({
    required String state,
    required String city,
    required String campus,
    required String universityName,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('initUniversity');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'state': state,
        'city': city,
        'campus': campus,
        'universityName': universityName,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('University initialization error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      print('General error in initializeUniversity: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get all universities (super admin only)
  Future<Map<String, dynamic>> getUniversities() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getUniversities');
      final HttpsCallableResult result = await callable.call();
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Get universities error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- User Management Functions ---

  /// Create a new user account
  Future<Map<String, dynamic>> createUserAccount({
    required String universityPath,
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('createUserAccount');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'name': name,
        'email': email,
        'userType': userType,
        'student_id': studentId,
        'department': department,
        'year_major': yearMajor,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Create user error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Update user account information
  Future<Map<String, dynamic>> updateUserAccount({
    required String universityPath,
    required String userId,
    String? name,
    String? email,
    String? department,
    String? yearMajor,
    String? acknowledgmentSigned,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('updateUserAccount');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'userId': userId,
        'name': name,
        'email': email,
        'department': department,
        'year_major': yearMajor,
        'acknowledgment_signed': acknowledgmentSigned,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Update user error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Assign mentor to mentee
  Future<Map<String, dynamic>> assignMentor({
    required String universityPath,
    required String mentorId,
    required String menteeId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('assignMentor');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentorId': mentorId,
        'menteeId': menteeId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Assign mentor error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Meeting Management Functions ---

  /// Schedule a new meeting
  Future<Map<String, dynamic>> scheduleMeeting({
    required String universityPath,
    required String mentorId,
    required String menteeId,
    required String startTime,
    String? endTime,
    String? topic,
    String? location,
    String? availabilityId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('scheduleMeeting');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'start_time': startTime,
        'end_time': endTime,
        'topic': topic,
        'location': location,
        'availability_id': availabilityId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Schedule meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Update meeting details
  Future<Map<String, dynamic>> updateMeetingDetails({
    required String universityPath,
    required String meetingId,
    String? startTime,
    String? endTime,
    String? topic,
    String? location,
    String? status,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('updateMeetingDetails');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
        'start_time': startTime,
        'end_time': endTime,
        'topic': topic,
        'location': location,
        'status': status,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Update meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Cancel a meeting
  Future<Map<String, dynamic>> cancelMeeting({
    required String universityPath,
    required String meetingId,
    String? reason,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('cancelMeeting');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
        'reason': reason,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Cancel meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Messaging Functions ---

  /// Send a chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String universityPath,
    required String chatId,
    required String message,
    String? recipientId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendChatMessage');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'chat_id': chatId,
        'message': message,
        'recipient_id': recipientId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Send message error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Get chat message history
  Future<Map<String, dynamic>> getChatMessages({
    required String universityPath,
    required String chatId,
    int? limit,
    int? offset,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getChatMessages');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'chat_id': chatId,
        'limit': limit,
        'offset': offset,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Get chat messages error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Announcement Functions ---

  /// Post a new announcement
  Future<Map<String, dynamic>> postAnnouncement({
    required String universityPath,
    required String title,
    required String content,
    required String priority,
    required String targetAudience,
    String? time,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('postAnnouncement');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'title': title,
        'content': content,
        'priority': priority,
        'target_audience': targetAudience,
        'time': time,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Post announcement error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Progress Report Functions ---

  /// Create a progress report
  Future<Map<String, dynamic>> createProgressReport({
    required String universityPath,
    required String menteeId,
    required String mentorId,
    required String reportPeriod,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('createProgressReport');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentee_id': menteeId,
        'mentor_id': mentorId,
        'report_period': reportPeriod,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Create progress report error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Submit a progress report
  Future<Map<String, dynamic>> submitReport({
    required String universityPath,
    required String reportId,
    int? overallScore,
    String? notes,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('submitReport');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'reportId': reportId,
        'overall_score': overallScore,
        'notes': notes,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Submit report error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Data Synchronization Functions ---

  /// Sync local database changes to Firestore
  Future<Map<String, dynamic>> syncData({
    required String universityPath,
    required String collection,
    required String operation,
    required Map<String, dynamic> document,
    String? localId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('syncData');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'collection': collection,
        'operation': operation,
        'document': document,
        'localId': localId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Sync data error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Utility Functions ---

  /// Health check for Cloud Functions
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('healthCheck');
      final HttpsCallableResult result = await callable.call();
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Health check error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Get current university path from user context
  String getCurrentUniversityPath() {
    // TODO: Implement logic to get university path from current user context
    // This would typically come from Firebase Auth custom claims or user preferences
    return 'California/Merced/UC_Merced'; // Default for now
  }
} 