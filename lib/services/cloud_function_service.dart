import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionService {
  // Singleton pattern setup
  static final CloudFunctionService _instance = CloudFunctionService._internal();
  factory CloudFunctionService() => _instance;

  late final FirebaseFunctions _functions;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize with proper configuration
  CloudFunctionService._internal() {
    // Initialize with specific region
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    
    // Check if we should use emulator based on various conditions
    bool shouldUseEmulator = false;
    
    // Method 1: Check compile-time environment variable
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    if (useEmulator == 'true') {
      shouldUseEmulator = true;
    }
    
    // Method 2: Check if running in debug mode and on localhost
    if (kDebugMode && kIsWeb) {
      // Check if running on localhost (development)
      final uri = Uri.base;
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        shouldUseEmulator = true;
      }
    }
    
    // Method 3: Check for explicit production flag
    if (kReleaseMode) {
      shouldUseEmulator = false;  // Never use emulator in release mode
    }
    
    if (shouldUseEmulator) {
      try {
        _functions.useFunctionsEmulator('localhost', 5001);
        print('🔥 Using local Firebase Functions emulator at localhost:5001');
      } catch (e) {
        print('⚠️ Failed to connect to emulator: $e');
        print('🔥 Falling back to production Firebase Functions');
      }
    } else {
      print('🔥 Using production Firebase Functions');
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
    String? acknowledgmentSigned,
  }) async {
    try {
      print('🔍 createUserAccount: Starting request');
      print('🔍 createUserAccount: universityPath: $universityPath');
      print('🔍 createUserAccount: name: $name, email: $email, userType: $userType');
      
      final HttpsCallable callable = _functions.httpsCallable('createUserAccount');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'name': name,
        'email': email,
        'userType': userType,
        'student_id': studentId,
        'department': department,
        'year_major': yearMajor,
        'acknowledgment_signed': acknowledgmentSigned,
      });
      
      print('🔍 createUserAccount: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 createUserAccount: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 createUserAccount: Exception details: ${e.details}');
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

  /// Get all users in a university
  Future<Map<String, dynamic>> getUsersList({
    required String universityPath,
  }) async {
    try {
      print('🔍 getUsersList: Starting request for universityPath: $universityPath');
      
      final HttpsCallable callable = _functions.httpsCallable('getUsersList');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
      });
      
      print('🔍 getUsersList: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 getUsersList: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 getUsersList: Exception details: ${e.details}');
      rethrow;
    }
  }

  /// Delete user account
  Future<Map<String, dynamic>> deleteUserAccount({
    required String universityPath,
    required String userId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('deleteUserAccount');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'userId': userId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Delete user error: ${e.code} ${e.message}');
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

  /// Hide a meeting from user's view
  Future<Map<String, dynamic>> hideMeeting({
    required String universityPath,
    required String meetingId,
  }) async {
    try {
      print('🔍 CloudFunctionService.hideMeeting: Starting');
      print('🔍 CloudFunctionService.hideMeeting: universityPath: $universityPath');
      print('🔍 CloudFunctionService.hideMeeting: meetingId: $meetingId');
      
      final HttpsCallable callable = _functions.httpsCallable('hideMeeting');
      print('🔍 CloudFunctionService.hideMeeting: Calling cloud function...');
      
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
      });
      
      print('🔍 CloudFunctionService.hideMeeting: Raw result data: ${result.data}');
      final resultMap = Map<String, dynamic>.from(result.data ?? {});
      print('🔍 CloudFunctionService.hideMeeting: Processed result: $resultMap');
      
      return resultMap;
    } on FirebaseFunctionsException catch (e) {
      print('🔍 CloudFunctionService.hideMeeting: FirebaseFunctionsException');
      print('🔍 CloudFunctionService.hideMeeting: Code: ${e.code}');
      print('🔍 CloudFunctionService.hideMeeting: Message: ${e.message}');
      print('🔍 CloudFunctionService.hideMeeting: Details: ${e.details}');
      rethrow;
    } catch (e) {
      print('🔍 CloudFunctionService.hideMeeting: Unknown error: $e');
      print('🔍 CloudFunctionService.hideMeeting: Error type: ${e.runtimeType}');
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
      final HttpsCallable callable = _functions.httpsCallable('deleteMeeting');  // Use exported name
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

  /// Create a new meeting
  Future<Map<String, dynamic>> createMeeting({
    required String universityPath,
    required String mentorId,
    required String menteeId,
    required String date,
    required String startTime,
    required String endTime,
    String? topic,
    String? location,
    String? availabilityId,
  }) async {
    try {
      print('🔍 createMeeting: Calling cloud function with:');
      print('🔍   universityPath: $universityPath');
      print('🔍   mentor_id: $mentorId');
      print('🔍   mentee_id: $menteeId');
      print('🔍   date: $date');
      print('🔍   start_time: $startTime');
      print('🔍   end_time: $endTime');
      print('🔍   topic: $topic');
      print('🔍   location: $location');
      print('🔍   availability_id: $availabilityId');
      
      // Combine date and time into full datetime strings
      final startDateTime = '${date}T${startTime}:00';
      final endDateTime = endTime.isNotEmpty ? '${date}T${endTime}:00' : null;
      
      final HttpsCallable callable = _functions.httpsCallable('scheduleMeeting');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'start_time': startDateTime,
        'end_time': endDateTime,
        'topic': topic,
        'location': location,
        'availability_id': availabilityId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Create meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Update an existing meeting
  Future<Map<String, dynamic>> updateMeeting({
    required String universityPath,
    required String meetingId,
    String? date,
    String? startTime,
    String? endTime,
    String? topic,
    String? location,
    String? status,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('updateMeetingDetails');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
        'date': date,
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

  // Note: acceptMeeting and rejectMeeting methods are defined later in the file
  // with automatic universityPath detection from user claims

  /// Set mentor availability for a specific day
  Future<Map<String, dynamic>> setMentorAvailability({
    required String universityPath,
    required String mentorId,
    required String day,
    required List<Map<String, dynamic>> slots,
  }) async {
    try {
      print('🔍 setMentorAvailability: Starting request');
      print('🔍 setMentorAvailability: universityPath: $universityPath');
      print('🔍 setMentorAvailability: mentorId: $mentorId');
      print('🔍 setMentorAvailability: day: $day');
      print('🔍 setMentorAvailability: slots count: ${slots.length}');
      print('🔍 setMentorAvailability: slots data: $slots');
      
      final HttpsCallable callable = _functions.httpsCallable(
        'setAvailability',  // Use the exported name from index.ts
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'day': day,
        'slots': slots,
      });
      
      print('🔍 setMentorAvailability: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 setMentorAvailability: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 setMentorAvailability: Exception details: ${e.details}');
      
      // If it's a CORS error in emulator, provide helpful message
      if (e.code == 'internal' && e.message == 'internal') {
        print('⚠️ CORS Error detected. Make sure:');
        print('   1. Firebase emulators are running (firebase emulators:start)');
        print('   2. Functions are built (cd functions && npm run build)');
        print('   3. You are accessing the app via http://localhost:PORT');
      }
      
      rethrow;
    } catch (e) {
      print('🔍 setMentorAvailability: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get mentor availability
  Future<Map<String, dynamic>> getMentorAvailability({
    required String universityPath,
    required String mentorId,
    String? day,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getAvailability');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'day': day,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Get mentor availability error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Get available slots for booking (for mentees)
  Future<Map<String, dynamic>> getAvailableSlots({
    required String universityPath,
    required String mentorId,
    String? day,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getBookableSlots');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'day': day,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Get available slots error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Remove specific availability slot
  Future<Map<String, dynamic>> removeAvailabilitySlot({
    required String universityPath,
    required String slotId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('removeAvailabilitySlot');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'slot_id': slotId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Remove availability slot error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Request a meeting at a custom time (for mentees)
  Future<Map<String, dynamic>> requestMeeting({
    required String universityPath,
    required String mentorId,
    required String menteeId,
    required String date,
    required String startTime,
    required String endTime,
    String? topic,
    String? location,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('requestMeetingTime');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'topic': topic,
        'location': location,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Request meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Accept a meeting request (mentor or mentee)
  Future<Map<String, dynamic>> acceptMeeting({
    required String meetingId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User must be authenticated',
        );
      }

      // Get university path from user claims
      final idTokenResult = await user.getIdTokenResult();
      final universityPath = idTokenResult.claims?['universityPath'] ?? 
                            idTokenResult.claims?['university_path'] ?? 
                            'universities/alabama';

      final HttpsCallable callable = _functions.httpsCallable('approveMeeting');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Accept meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Reject a meeting request (mentor or mentee)
  Future<Map<String, dynamic>> rejectMeeting({
    required String meetingId,
    String? rejectionReason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User must be authenticated',
        );
      }

      // Get university path from user claims
      final idTokenResult = await user.getIdTokenResult();
      final universityPath = idTokenResult.claims?['universityPath'] ?? 
                            idTokenResult.claims?['university_path'] ?? 
                            'universities/alabama';

      final HttpsCallable callable = _functions.httpsCallable('declineMeeting');  // Use exported name
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'meetingId': meetingId,
        'reason': rejectionReason,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Reject meeting error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // --- Messaging Functions ---

  /// Create a new chat conversation
  /// Note: This function expects Firestore document IDs (e.g., "Emerald_Nash"), not Firebase Auth UIDs
  /// The Cloud Function will verify the current user is one of the participants
  Future<Map<String, dynamic>> createChatConversation({
    required String user1Id,
    required String user2Id,
    String? mentorshipId,
  }) async {
    print('🔍 CloudFunctionService.createChatConversation - START');
    print('  user1Id: $user1Id');
    print('  user2Id: $user2Id');
    print('  mentorshipId: $mentorshipId');
    
    try {
      final params = <String, dynamic>{
        'user1Id': user1Id,
        'user2Id': user2Id,
        if (mentorshipId != null) 'mentorshipId': mentorshipId,
      };
      print('  Request parameters: $params');
      
      final HttpsCallable callable = _functions.httpsCallable('createChatConversation');
      final HttpsCallableResult result = await callable.call(params);
      
      final responseData = Map<String, dynamic>.from(result.data ?? {});
      print('  Response data: $responseData');
      print('  Response success: ${responseData['success']}');
      print('  Response message: ${responseData['message']}');
      print('  Response conversationId: ${responseData['conversationId']}');
      
      return responseData;
    } on FirebaseFunctionsException catch (e) {
      print('  ❌ FirebaseFunctionsException:');
      print('    Code: ${e.code}');
      print('    Message: ${e.message}');
      print('    Details: ${e.details}');
      print('    Full exception: $e');
      
      // Return error response instead of rethrowing
      return {
        'success': false,
        'message': e.message ?? 'Cloud function error',
        'error': {
          'code': e.code,
          'message': e.message,
          'details': e.details,
        }
      };
    } catch (e, stackTrace) {
      print('  ❌ Unexpected error:');
      print('    Error type: ${e.runtimeType}');
      print('    Error message: $e');
      print('    Stack trace: $stackTrace');
      
      // Return error response
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'error': {
          'type': e.runtimeType.toString(),
          'message': e.toString(),
        }
      };
    } finally {
      print('🔍 CloudFunctionService.createChatConversation - END');
    }
  }

  /// Send a message in a conversation
  Future<Map<String, dynamic>> sendChatMessage({
    required String conversationId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? media,
  }) async {
    print('🔍 CloudFunctionService.sendChatMessage - START');
    print('  conversationId: $conversationId');
    print('  message: $message');
    print('  type: $type');
    print('  media: $media');
    
    try {
      final params = <String, dynamic>{
        'conversationId': conversationId,
        'message': message,
        'type': type,
        if (media != null) 'media': media,
      };
      print('  Request parameters: $params');
      
      final HttpsCallable callable = _functions.httpsCallable('sendChatMessage');
      final HttpsCallableResult result = await callable.call(params);
      
      final responseData = Map<String, dynamic>.from(result.data ?? {});
      print('  Response data: $responseData');
      print('  Response success: ${responseData['success']}');
      print('  Response message: ${responseData['message']}');
      
      return responseData;
    } on FirebaseFunctionsException catch (e) {
      print('  ❌ FirebaseFunctionsException:');
      print('    Code: ${e.code}');
      print('    Message: ${e.message}');
      print('    Details: ${e.details}');
      
      // Return error response instead of rethrowing
      return {
        'success': false,
        'message': e.message ?? 'Cloud function error',
        'error': {
          'code': e.code,
          'message': e.message,
          'details': e.details,
        }
      };
    } catch (e, stackTrace) {
      print('  ❌ Unexpected error:');
      print('    Error type: ${e.runtimeType}');
      print('    Error message: $e');
      print('    Stack trace: $stackTrace');
      
      // Return error response
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'error': {
          'type': e.runtimeType.toString(),
          'message': e.toString(),
        }
      };
    } finally {
      print('🔍 CloudFunctionService.sendChatMessage - END');
    }
  }

  /// Mark messages as read
  Future<Map<String, dynamic>> markChatMessagesRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('markChatMessagesRead');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'conversationId': conversationId,
        'messageIds': messageIds,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Mark messages read error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Update conversation settings
  Future<Map<String, dynamic>> updateChatSettings({
    required String conversationId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('updateChatSettings');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'conversationId': conversationId,
        'settings': settings,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Update chat settings error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Send a chat message (OLD - for backward compatibility)
  Future<Map<String, dynamic>> sendChatMessageOld({
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

  // --- Acknowledgment Functions ---

  /// Check if a mentee has completed their acknowledgment
  Future<Map<String, dynamic>> checkMenteeAcknowledgment() async {
    try {
      print('🔍 checkMenteeAcknowledgment: Calling cloud function');
      
      final HttpsCallable callable = _functions.httpsCallable('checkMenteeAcknowledgmentStatus');
      final HttpsCallableResult result = await callable.call();
      
      final responseData = Map<String, dynamic>.from(result.data ?? {});
      print('🔍 checkMenteeAcknowledgment: Cloud function response:');
      print('  - success: ${responseData['success']}');
      print('  - needsAcknowledgment: ${responseData['needsAcknowledgment']}');
      print('  - acknowledgmentStatus: ${responseData['acknowledgmentStatus']}');
      print('  - message: ${responseData['message']}');
      print('  - Full response: $responseData');
      
      return responseData;
    } on FirebaseFunctionsException catch (e) {
      print('Check mentee acknowledgment error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Submit mentee acknowledgment
  Future<Map<String, dynamic>> submitMenteeAcknowledgment({
    required String fullName,
  }) async {
    try {
      print('🔍 submitMenteeAcknowledgment: Calling cloud function');
      print('🔍   fullName: $fullName');
      
      final HttpsCallable callable = _functions.httpsCallable('submitMenteeAcknowledgmentForm');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'fullName': fullName,
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Submit mentee acknowledgment error: ${e.code} ${e.message}');
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

  // --- Bulk Import Functions ---

  /// Bulk create users from Excel import
  Future<Map<String, dynamic>> bulkCreateUsers({
    required String universityPath,
    required List<Map<String, dynamic>> users,
  }) async {
    try {
      print('🔍 bulkCreateUsers: Starting request with ${users.length} users');
      print('🔍 bulkCreateUsers: universityPath: $universityPath');
      
      final HttpsCallable callable = _functions.httpsCallable('bulkCreateUserAccounts');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'users': users,
      });
      
      print('🔍 bulkCreateUsers: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 bulkCreateUsers: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 bulkCreateUsers: Exception details: ${e.details}');
      rethrow;
    } catch (e) {
      print('🔍 bulkCreateUsers: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Bulk assign mentors to mentees
  Future<Map<String, dynamic>> bulkAssignMentors({
    required String universityPath,
    required List<Map<String, dynamic>> assignments,
  }) async {
    try {
      print('🔍 bulkAssignMentors: Starting request with ${assignments.length} assignments');
      print('🔍 bulkAssignMentors: universityPath: $universityPath');
      
      final HttpsCallable callable = _functions.httpsCallable('bulkAssignMentorAccounts');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'assignments': assignments,
      });
      
      print('🔍 bulkAssignMentors: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 bulkAssignMentors: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 bulkAssignMentors: Exception details: ${e.details}');
      rethrow;
    } catch (e) {
      print('🔍 bulkAssignMentors: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Migrate existing users to add missing subcollections
  Future<Map<String, dynamic>> migrateUserSubcollections({
    required String universityPath,
    List<String>? userIds,  // Optional: migrate specific users
    bool dryRun = false,    // Optional: just check what would be migrated
  }) async {
    try {
      print('🔍 migrateUserSubcollections: Starting migration${dryRun ? ' (dry run)' : ''}');
      print('🔍 migrateUserSubcollections: universityPath: $universityPath');
      if (userIds != null) {
        print('🔍 migrateUserSubcollections: targeting ${userIds.length} specific users');
      }
      
      final HttpsCallable callable = _functions.httpsCallable('migrateUserSubcollectionsForUniversity');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        if (userIds != null) 'userIds': userIds,
        'dryRun': dryRun,
      });
      
      print('🔍 migrateUserSubcollections: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 migrateUserSubcollections: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      print('🔍 migrateUserSubcollections: Exception details: ${e.details}');
      rethrow;
    } catch (e) {
      print('🔍 migrateUserSubcollections: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get current university path from user context
  String getCurrentUniversityPath() {
    // TODO: Implement logic to get university path from current user context
    // This would typically come from Firebase Auth custom claims or user preferences
    final universityPath = 'california_merced_uc_merced'; // Correct path as confirmed
    print('🔍 CloudFunctionService.getCurrentUniversityPath: $universityPath');
    return universityPath;
  }

  // --- Announcement Management Functions ---

  /// Create a new announcement
  Future<Map<String, dynamic>> createAnnouncement({
    required String universityPath,
    required String title,
    required String content,
    required String priority,
    required String targetAudience,
    String? time,
  }) async {
    try {
      print('🔍 createAnnouncement: Starting request');
      print('🔍 createAnnouncement: title: $title, priority: $priority, audience: $targetAudience');
      
      final HttpsCallable callable = _functions.httpsCallable('postAnnouncement');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'title': title,
        'content': content,
        'priority': priority,
        'target_audience': targetAudience,
        if (time != null) 'time': time,
      });
      
      print('🔍 createAnnouncement: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 createAnnouncement: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔍 createAnnouncement: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Update an existing announcement
  Future<Map<String, dynamic>> updateAnnouncement({
    required String universityPath,
    required String announcementId,
    String? title,
    String? content,
    String? priority,
    String? targetAudience,
    String? time,
  }) async {
    try {
      print('🔍 updateAnnouncement: Starting request for announcement: $announcementId');
      
      final HttpsCallable callable = _functions.httpsCallable('updateAnnouncementDetails');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'announcementId': announcementId,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (priority != null) 'priority': priority,
        if (targetAudience != null) 'target_audience': targetAudience,
        if (time != null) 'time': time,
      });
      
      print('🔍 updateAnnouncement: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 updateAnnouncement: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔍 updateAnnouncement: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Delete an announcement
  Future<Map<String, dynamic>> deleteAnnouncement({
    required String universityPath,
    required String announcementId,
  }) async {
    try {
      print('🔍 deleteAnnouncement: Starting request for announcement: $announcementId');
      
      final HttpsCallable callable = _functions.httpsCallable('removeAnnouncement');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'announcementId': announcementId,
      });
      
      print('🔍 deleteAnnouncement: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 deleteAnnouncement: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔍 deleteAnnouncement: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get announcements for target audience
  Future<Map<String, dynamic>> getAnnouncements({
    required String universityPath,
    required String userType,
    int? limit,
  }) async {
    try {
      print('🔍 getAnnouncements: Starting request for userType: $userType');
      
      final HttpsCallable callable = _functions.httpsCallable('getAnnouncementsList');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
        'userType': userType,
        if (limit != null) 'limit': limit,
      });
      
      print('🔍 getAnnouncements: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔍 getAnnouncements: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔍 getAnnouncements: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Sync user claims on login to ensure proper permissions
  Future<Map<String, dynamic>> syncUserClaimsOnLogin() async {
    try {
      print('🔐 syncUserClaimsOnLogin: Starting request');
      
      final HttpsCallable callable = _functions.httpsCallable('syncUserClaimsOnLogin');
      final HttpsCallableResult result = await callable.call();
      
      print('🔐 syncUserClaimsOnLogin: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔐 syncUserClaimsOnLogin: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Set custom claims for newly registered users
  Future<Map<String, dynamic>> setCustomClaimsOnRegistration({
    required String uid,
  }) async {
    try {
      print('🔐 setCustomClaimsOnRegistration: Starting request for UID: $uid');
      
      final HttpsCallable callable = _functions.httpsCallable('setCustomClaimsOnRegistration');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'uid': uid,
      });
      
      print('🔐 setCustomClaimsOnRegistration: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔐 setCustomClaimsOnRegistration: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔐 setCustomClaimsOnRegistration: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Sync all user claims for a university (coordinator only)
  Future<Map<String, dynamic>> syncUserClaimsForUniversity({
    required String universityPath,
  }) async {
    try {
      print('🔐 syncUserClaimsForUniversity: Starting request for university: $universityPath');
      
      final HttpsCallable callable = _functions.httpsCallable('syncUserClaimsForUniversity');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'universityPath': universityPath,
      });
      
      print('🔐 syncUserClaimsForUniversity: Success - received data: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🔐 syncUserClaimsForUniversity: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔐 syncUserClaimsForUniversity: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // --- Test Runner Functions ---

  /// Run a unit test (developer only)
  static Future<Map<String, dynamic>> runUnitTest(
    String testPath, {
    int timeout = 60000,
    bool showDetailedLogs = true,
  }) async {
    try {
      print('🧪 runUnitTest: Starting test for path: $testPath');
      
      final instance = CloudFunctionService();
      final HttpsCallable callable = instance._functions.httpsCallable('runUnitTest');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'testPath': testPath,
        'timeout': timeout,
        'showDetailedLogs': showDetailedLogs,
      });
      
      print('🧪 runUnitTest: Test completed');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🧪 runUnitTest: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🧪 runUnitTest: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Run a test suite (developer only)
  static Future<Map<String, dynamic>> runTestSuite(String suite) async {
    try {
      print('🧪 runTestSuite: Starting test suite: $suite');
      
      final instance = CloudFunctionService();
      final HttpsCallable callable = instance._functions.httpsCallable('runTestSuite');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'suite': suite,
      });
      
      print('🧪 runTestSuite: Test suite completed');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('🧪 runTestSuite: FirebaseFunctionsException - code: ${e.code}, message: ${e.message}');
      rethrow;
    } catch (e) {
      print('🧪 runTestSuite: General error: $e');
      throw FirebaseFunctionsException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
} 