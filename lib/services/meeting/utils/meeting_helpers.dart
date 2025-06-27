import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_constants.dart';

/// Helper functions for the meeting service
class MeetingHelpers {
  /// Generate a human-readable meeting ID
  /// Format: {mentorDocId}__{menteeDocId}__{timestamp}
  static String generateMeetingId(String mentorDocId, String menteeDocId, DateTime startTime) {
    final timestamp = startTime.millisecondsSinceEpoch ~/ 1000;
    return '$mentorDocId${MeetingConstants.meetingIdSeparator}$menteeDocId${MeetingConstants.meetingIdSeparator}$timestamp';
  }
  
  /// Parse meeting ID to extract mentor and mentee document IDs
  static Map<String, String>? parseMeetingId(String meetingId) {
    final parts = meetingId.split(MeetingConstants.meetingIdSeparator);
    if (parts.length >= 3) {
      return {
        'mentorDocId': parts[0],
        'menteeDocId': parts[1],
        'timestamp': parts[2],
      };
    }
    return null;
  }
  
  /// Generate availability slot ID
  /// Format: {mentorDocId}__{timestamp}
  static String generateAvailabilityId(String mentorDocId, DateTime slotTime) {
    final timestamp = slotTime.millisecondsSinceEpoch ~/ 1000;
    return '$mentorDocId${MeetingConstants.meetingIdSeparator}$timestamp';
  }
  
  /// Convert Timestamp to ISO string
  static String timestampToIsoString(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toIso8601String();
    } else if (timestamp is String) {
      return timestamp;
    }
    return '';
  }
  
  /// Convert string time to DateTime for a specific date
  /// Example: "14:00" on "2024-01-15" -> DateTime
  static DateTime? parseTimeSlot(String date, String time) {
    try {
      return DateTime.parse('${date}T$time:00');
    } catch (e) {
      return null;
    }
  }
  
  /// Check if a document should be skipped (metadata documents)
  static bool shouldSkipDocument(String docId) {
    return docId == MeetingConstants.metadataDocName || 
           docId.startsWith(MeetingConstants.metadataDocPrefix);
  }
  
  /// Get week number for a date (ISO week number)
  static int getWeekNumber(DateTime date) {
    // Calculate the Thursday of the week (ISO 8601)
    final thursday = date.add(Duration(days: 4 - date.weekday));
    // Find the first Thursday of the year
    final firstThursday = DateTime(thursday.year, 1, 1);
    final daysToFirstThursday = firstThursday.weekday == DateTime.thursday 
        ? 0 
        : (8 - firstThursday.weekday + DateTime.thursday) % 7;
    final firstThursdayOfYear = firstThursday.add(Duration(days: daysToFirstThursday));
    
    // Calculate week number
    final weekNumber = ((thursday.difference(firstThursdayOfYear).inDays) / 7).floor() + 1;
    return weekNumber;
  }
  
  /// Format date for display
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Get month-year string for grouping
  static String getMonthYear(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
  
  /// Create a query-friendly compound field
  static String createCompoundField(String field1, String field2) {
    return '${field1}_${field2}';
  }
  
  /// Add one hour to a time string
  static String addHour(String time) {
    final parts = time.split(':').map(int.parse).toList();
    if (parts.length >= 2) {
      final hours = (parts[0] + 1) % 24;
      final minutes = parts[1];
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return time;
  }
}