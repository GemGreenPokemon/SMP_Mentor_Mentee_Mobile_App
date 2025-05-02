import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionService {
  // Singleton pattern setup
  static final CloudFunctionService _instance = CloudFunctionService._internal();
  factory CloudFunctionService() => _instance;
  CloudFunctionService._internal();

  // Optional: Initialize FirebaseFunctions instance with region if needed
  // final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'your-region');
  final FirebaseFunctions _functions = FirebaseFunctions.instance; 

  // --- Function Calling Methods --- 

  // Example: Function to assign a mentee to a mentor
  Future<Map<String, dynamic>> assignMenteeToMentor({
    required String mentorId, // Or student_id
    required String menteeId, // Or student_id
  }) async {
    try {
      // Get a callable function reference
      final HttpsCallable callable = _functions.httpsCallable('assignMenteeToMentor'); // Name matches deployed function
      
      // Call the function with parameters
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'mentorId': mentorId,
        'menteeId': menteeId,
      });

      // Return the result data (or handle specific success/error codes)
      print('Cloud function assignMenteeToMentor result: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Cloud function error: ${e.code} ${e.message}');
      // Rethrow or handle specific errors
      rethrow; 
    } catch (e) {
       print('Generic error calling cloud function: $e');
       rethrow;
    }
  }

  // Example: Function to process meeting notes with AI
  Future<Map<String, dynamic>> organizeMeetingNote({
    required String noteId,
  }) async {
     try {
      final HttpsCallable callable = _functions.httpsCallable('organizeMeetingNote');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'noteId': noteId,
      });
      print('Cloud function organizeMeetingNote result: ${result.data}');
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Cloud function error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
       print('Generic error calling cloud function: $e');
       rethrow;
    }
  }

  // TODO: Add methods for other cloud functions you plan to implement
  // e.g., handleMeetingRating, syncWithBox, processQualtricsData, etc.

} 