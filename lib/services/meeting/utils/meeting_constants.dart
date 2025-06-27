/// Constants used throughout the meeting service
class MeetingConstants {
  // Collection names
  static const String meetingsCollection = 'meetings';
  static const String availabilityCollection = 'availability';
  static const String usersCollection = 'users';
  
  // Meeting status values
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String statusCancelled = 'cancelled';
  static const String statusCompleted = 'completed';
  
  // Field names for queries
  static const String fieldMentorUid = 'mentor_id';  // Changed to match the array structure
  static const String fieldMenteeUid = 'mentee_uid';
  static const String fieldMentorDocId = 'mentor_doc_id';
  static const String fieldMenteeDocId = 'mentee_doc_id';
  static const String fieldStartTime = 'start_time';
  static const String fieldEndTime = 'end_time';
  static const String fieldStatus = 'status';
  static const String fieldDate = 'day';  // Changed to match the array structure
  static const String fieldIsBooked = 'is_booked';
  
  // Cache keys
  static const String cacheKeyUserDocId = 'user_doc_id_';
  static const String cacheKeyUserData = 'user_data_';
  
  // Metadata document names
  static const String metadataDocPrefix = '_';
  static const String metadataDocName = '_metadata';
  
  // Meeting ID separator
  static const String meetingIdSeparator = '__';
  
  // Error messages
  static const String errorUserNotAuthenticated = 'User not authenticated';
  static const String errorUserDocumentNotFound = 'User document not found';
  static const String errorMeetingCreationFailed = 'Failed to create meeting';
  static const String errorAvailabilityCreationFailed = 'Failed to create availability';
}