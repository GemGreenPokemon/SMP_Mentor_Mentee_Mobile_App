import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_function_service.dart';
import 'auth_service.dart';

class DashboardDataService {
  static final DashboardDataService _instance = DashboardDataService._internal();
  factory DashboardDataService() => _instance;
  DashboardDataService._internal();

  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
  
  String get _universityPath => _cloudFunctions.getCurrentUniversityPath();

  void _initializeFirestore() {
    if (_isFirestoreInitialized) {
      return;
    }
    
    _firestore = FirebaseFirestore.instance;
    
    // Use emulator when running locally
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    
    if (useEmulator == 'true' || kDebugMode) {
      try {
        _firestore!.useFirestoreEmulator('127.0.0.1', 8080);
        if (kDebugMode) {
          print('🔥 Dashboard service connected to Firestore emulator');
        }
      } catch (e) {
        // Already connected or emulator not available
      }
    }
    
    _isFirestoreInitialized = true;
  }

  Future<Map<String, dynamic>> getMentorDashboardData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Initialize Firestore
      _initializeFirestore();

      if (kDebugMode) {
        print('🔥 Dashboard: Getting mentor data for user ${currentUser.uid}');
      }

      // Get the mentor's user document from Firestore (similar to AuthService pattern)
      final usersSnapshot = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .where('firebase_uid', isEqualTo: currentUser.uid)
          .get();

      Map<String, dynamic> mentorData = {};
      List<Map<String, dynamic>> menteesList = [];

      if (usersSnapshot.docs.isNotEmpty) {
        mentorData = usersSnapshot.docs.first.data();
        
        if (kDebugMode) {
          print('🔥 Dashboard: Found mentor data: ${mentorData['name']}');
          print('🔥 Dashboard: Mentor mentees field: ${mentorData['mentee']}');
        }

        // Get mentees if they exist in the mentor's document
        if (mentorData['mentee'] != null) {
          var menteeNames = mentorData['mentee'];
          
          if (kDebugMode) {
            print('🔥 Dashboard: Raw mentee data type: ${menteeNames.runtimeType}');
            print('🔥 Dashboard: Raw mentee data: $menteeNames');
          }
          
          // Handle mentee array format: ["Name1", "Name2", "Name3"]
          List<String> menteeNameList = [];
          
          if (menteeNames is List) {
            if (kDebugMode) {
              print('🔥 Dashboard: menteeNames is a List with ${menteeNames.length} items');
            }
            
            // Simply cast to List<String> and trim names
            menteeNameList = menteeNames.cast<String>().map((name) => name.trim()).toList();
            
            if (kDebugMode) {
              print('🔥 Dashboard: Processed mentee names: $menteeNameList');
            }
          } else if (menteeNames is String) {
            menteeNameList = [menteeNames.trim()];
          }

          if (kDebugMode) {
            print('🔥 Dashboard: Final processing ${menteeNameList.length} mentees');
            print('🔥 Dashboard: Final mentee names: $menteeNameList');
          }

          // Fetch each mentee's data by searching for their name
          for (String menteeName in menteeNameList) {
            try {
              if (kDebugMode) {
                print('🔥 Dashboard: Searching for mentee with name: "$menteeName"');
              }

              final menteeQuery = await _firestore!
                  .collection(_universityPath)
                  .doc('data')
                  .collection('users')
                  .where('name', isEqualTo: menteeName.trim())
                  .get();

              if (menteeQuery.docs.isNotEmpty) {
                final menteeDoc = menteeQuery.docs.first;
                final menteeData = menteeDoc.data();
                
                menteesList.add({
                  'id': menteeDoc.id,
                  'firebase_uid': menteeData['firebase_uid'] ?? '',
                  'name': menteeData['name'] ?? 'Unknown',
                  'program': '${menteeData['year_major'] ?? 'Unknown Year'}, ${menteeData['department'] ?? 'Unknown Dept'}',
                  'progress': 0.65, // TODO: Calculate from actual progress data
                  'lastMeeting': 'Jan 15, 2024', // TODO: Get from meetings
                  'assignedBy': 'Coordinator',
                  'goals': [
                    {'goal': 'Complete first semester', 'completed': true},
                    {'goal': 'Join study group', 'completed': false},
                  ],
                  'upcomingMeetings': await _getMenteeUpcomingMeetings(menteeDoc.id, currentUser.uid),
                  'actionItems': [
                    {
                      'item': 'Review biology notes',
                      'dueDate': 'Tomorrow',
                    }
                  ],
                });

                if (kDebugMode) {
                  print('🔥 Dashboard: Added mentee: ${menteeData['name']} (${menteeData['year_major']}, ${menteeData['department']})');
                  print('🔥 Dashboard: Mentee firebase_uid: ${menteeData['firebase_uid'] ?? 'Not found'}');
                }
              } else {
                if (kDebugMode) {
                  print('🔥 Dashboard: No mentee found with name: "$menteeName"');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('🔥 Dashboard: Error fetching mentee "$menteeName": $e');
              }
            }
          }
        }
      } else {
        // Fallback if no user document found
        if (kDebugMode) {
          print('🔥 Dashboard: No mentor document found, using fallback data');
        }
        mentorData = {
          'name': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Mentor',
          'department': 'Computer Science',
          'year_major': '3rd Year, Computer Science Major',
        };
      }

      final mentorProfile = {
        'name': mentorData['name'] ?? (currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Mentor'),
        'id': currentUser.uid,
        'email': currentUser.email,
        'department': mentorData['department'] ?? 'Computer Science',
        'year_major': mentorData['year_major'] ?? '3rd Year, Computer Science Major',
      };

      // Get real announcements from Firebase
      List<Map<String, dynamic>> announcementsList = [];
      try {
        final announcementsResult = await _cloudFunctions.getAnnouncements(
          universityPath: _universityPath,
          userType: 'mentor',
          limit: 10,
        );
        
        if (announcementsResult['success'] == true && announcementsResult['data'] != null) {
          final List<dynamic> rawAnnouncements = announcementsResult['data'];
          announcementsList = rawAnnouncements.map((announcement) {
            final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
            return {
              'id': announcementMap['id'],
              'title': announcementMap['title'],
              'content': announcementMap['content'],
              'time': _formatAnnouncementTime(announcementMap['created_at']),
              'priority': announcementMap['priority'] ?? 'none',
            };
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 Dashboard: Error fetching announcements: $e');
        }
        // Fall back to empty list if error occurs
      }

      // Get upcoming meetings for the mentor
      final upcomingMeetings = await _getUpcomingMeetingsForMentor(currentUser.uid);

      return {
        'mentorProfile': mentorProfile,
        'mentees': menteesList,
        'announcements': announcementsList,
        'upcomingMeetings': upcomingMeetings,
        'recentActivity': [
          {
            'text': 'New mentee assigned: ${menteesList.isNotEmpty ? menteesList.last['name'] : 'None'}',
            'time': '2 hours ago',
            'icon': 'person_add',
            'color': 'blue',
          },
          {
            'text': 'Meeting completed with ${menteesList.isNotEmpty ? menteesList.first['name'] : 'mentee'}',
            'time': 'Yesterday',
            'icon': 'check_circle',
            'color': 'green',
          },
        ],
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching mentor dashboard data: $e');
      }
      rethrow;
    }
  }

  /// Get upcoming meetings for a mentee
  Future<List<Map<String, dynamic>>> _getMenteeUpcomingMeetings(String menteeDocId, String mentorFirebaseUid) async {
    try {
      _initializeFirestore();
      
      // Determine if we're in emulator mode
      final isEmulator = kDebugMode || const String.fromEnvironment('USE_EMULATOR', defaultValue: 'false') == 'true';
      
      // Get mentor's document ID if in emulator mode
      String mentorIdentifier = mentorFirebaseUid;
      if (isEmulator) {
        // First get the mentor's document to find their doc ID
        final mentorQuery = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('users')
            .where('firebase_uid', isEqualTo: mentorFirebaseUid)
            .limit(1)
            .get();
            
        if (mentorQuery.docs.isNotEmpty) {
          mentorIdentifier = mentorQuery.docs.first.id;
        }
      }
      
      final now = DateTime.now();
      // Query using appropriate fields based on environment
      final mentorField = isEmulator ? 'mentor_doc_id' : 'mentor_uid';
      
      final meetings = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('mentee_doc_id', isEqualTo: menteeDocId)
          .where(mentorField, isEqualTo: mentorIdentifier)
          .where('status', whereIn: ['pending', 'accepted', 'confirmed', 'cancelled', 'rejected'])
          .orderBy('start_time')
          .limit(3)
          .get();
      
      final upcomingMeetings = <Map<String, dynamic>>[];
      bool isFirst = true;
      
      for (final doc in meetings.docs) {
        final data = doc.data();
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        final endTime = (data['end_time'] as Timestamp?)?.toDate();
        
        if (startTime != null && _shouldShowMeeting(startTime, endTime, now)) {
          upcomingMeetings.add({
            'title': data['topic'] ?? 'Meeting',
            'date': _formatMeetingDate(startTime),
            'time': _formatMeetingTime(startTime),
            'location': data['location'] ?? 'TBD',
            'isNext': isFirst,
          });
          isFirst = false;
        }
      }
      
      // If no upcoming meetings, return a placeholder
      if (upcomingMeetings.isEmpty) {
        upcomingMeetings.add({
          'title': 'No scheduled meetings',
          'date': 'Schedule one',
          'time': 'with your mentor',
          'location': 'TBD',
          'isNext': false,
        });
      }
      
      return upcomingMeetings;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting upcoming meetings: $e');
      }
      return [{
        'title': 'Weekly Check-in',
        'date': 'Tomorrow',
        'time': '2:00 PM - 3:00 PM',
        'location': 'KL 109',
        'isNext': true,
      }];
    }
  }
  
  /// Format meeting date for display
  String _formatMeetingDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (date.difference(now).inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}';
    }
  }
  
  /// Format meeting time for display
  String _formatMeetingTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
  
  /// Check if a meeting should be shown (upcoming or ongoing)
  bool _shouldShowMeeting(DateTime startTime, DateTime? endTime, DateTime now) {
    // If meeting hasn't started yet, show it
    if (startTime.isAfter(now)) {
      return true;
    }
    
    // If meeting has started, check if it's still ongoing
    if (endTime != null) {
      // If end time is specified, show until end time passes
      return now.isBefore(endTime);
    } else {
      // If no end time, assume 1 hour duration as default
      final defaultEndTime = startTime.add(const Duration(hours: 1));
      return now.isBefore(defaultEndTime);
    }
  }
  
  /// Get upcoming meetings for the mentor across all their mentees
  Future<List<Map<String, dynamic>>> _getUpcomingMeetingsForMentor(String mentorFirebaseUid) async {
    try {
      _initializeFirestore();
      
      // Determine if we're in emulator mode
      final isEmulator = kDebugMode || const String.fromEnvironment('USE_EMULATOR', defaultValue: 'false') == 'true';
      
      if (kDebugMode) {
        print('🔥 Dashboard: Getting upcoming meetings for mentor');
        print('🔥 Dashboard: Firebase UID: $mentorFirebaseUid');
        print('🔥 Dashboard: Using emulator mode: $isEmulator');
        print('🔥 Dashboard: University path: $_universityPath');
      }
      
      // Get mentor's document ID if in emulator mode
      String mentorIdentifier = mentorFirebaseUid;
      if (isEmulator) {
        // First get the mentor's document to find their doc ID
        final mentorQuery = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('users')
            .where('firebase_uid', isEqualTo: mentorFirebaseUid)
            .limit(1)
            .get();
            
        if (mentorQuery.docs.isNotEmpty) {
          mentorIdentifier = mentorQuery.docs.first.id;
          if (kDebugMode) {
            print('🔥 Dashboard: Found mentor doc ID: $mentorIdentifier');
          }
        } else {
          if (kDebugMode) {
            print('🔥 Dashboard: Could not find mentor document for UID: $mentorFirebaseUid');
          }
        }
      }
      
      // Query meetings using the appropriate field based on environment
      final fieldToQuery = isEmulator ? 'mentor_doc_id' : 'mentor_uid';
      
      if (kDebugMode) {
        print('🔥 Dashboard: Querying meetings where $fieldToQuery = $mentorIdentifier');
      }
      
      // Try compound query first
      QuerySnapshot<Map<String, dynamic>> meetingsSnapshot;
      
      try {
        final now = DateTime.now();
        meetingsSnapshot = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('meetings')
            .where(fieldToQuery, isEqualTo: mentorIdentifier)
            .where('status', whereIn: ['pending', 'accepted', 'confirmed', 'cancelled', 'rejected'])
            .orderBy('start_time')
            .limit(10)
            .get();
            
        if (kDebugMode) {
          print('🔥 Dashboard: Compound query successful');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 Dashboard: Compound query failed, trying simpler query: $e');
        }
        
        // Fallback: Try simpler query without status filter
        meetingsSnapshot = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('meetings')
            .where(fieldToQuery, isEqualTo: mentorIdentifier)
            .orderBy('start_time')
            .limit(20)
            .get();
      }
      
      if (kDebugMode) {
        print('🔥 Dashboard: Found ${meetingsSnapshot.docs.length} total meetings');
        
        // Debug: Print first few meetings
        int count = 0;
        for (final doc in meetingsSnapshot.docs) {
          if (count++ >= 3) break;
          final data = doc.data();
          print('🔥 Dashboard: Meeting ${doc.id}:');
          print('  - mentor_doc_id: ${data['mentor_doc_id']}');
          print('  - mentor_uid: ${data['mentor_uid']}');
          print('  - mentee_name: ${data['mentee_name']}');
          print('  - topic: ${data['topic']}');
          print('  - status: ${data['status']}');
          print('  - start_time: ${data['start_time']}');
        }
      }
      
      final upcomingMeetings = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      for (final doc in meetingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        
        // Filter by status if compound query failed
        if (!['pending', 'accepted', 'confirmed', 'cancelled', 'rejected'].contains(status)) {
          continue;
        }
        
        // Filter out meetings hidden by the current user
        final hiddenBy = List<String>.from(data['hidden_by'] ?? []);
        if (kDebugMode) {
          print('🔥 Dashboard: Meeting ${doc.id} hidden_by: $hiddenBy');
          print('🔥 Dashboard: Current mentor UID: $mentorFirebaseUid');
          print('🔥 Dashboard: Is hidden by current user: ${hiddenBy.contains(mentorFirebaseUid)}');
        }
        if (hiddenBy.contains(mentorFirebaseUid)) {
          if (kDebugMode) {
            print('🔥 Dashboard: ❌ Skipping meeting ${doc.id} - hidden by current user');
          }
          continue;
        }
        
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        final endTime = (data['end_time'] as Timestamp?)?.toDate();
        
        if (startTime != null && _shouldShowMeeting(startTime, endTime, now)) {
          // Use denormalized mentee name from the meeting document
          final menteeName = data['mentee_name'] ?? 'Unknown Mentee';
          
          upcomingMeetings.add({
            'id': doc.id,
            'title': data['topic'] ?? 'Meeting',
            'menteeName': menteeName,
            'time': '${_formatMeetingDate(startTime)} at ${_formatMeetingTime(startTime)}',
            'location': data['location'] ?? 'TBD',
            'color': _getMeetingColor(upcomingMeetings.length),
            'startTime': startTime.toIso8601String(),
            'status': status,
            'createdBy': data['created_by'],
            'cancellationReason': data['cancellation_reason'],
            'cancelledBy': data['cancelled_by'],
          });
          
          if (kDebugMode) {
            print('🔥 Dashboard: Added upcoming meeting: ${data['topic']} with $menteeName');
          }
        }
      }
      
      if (kDebugMode) {
        print('🔥 Dashboard: Returning ${upcomingMeetings.length} upcoming meetings');
      }
      
      return upcomingMeetings;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Dashboard: Error getting upcoming meetings: $e');
        print('🔥 Dashboard: Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }
  
  /// Get color for meeting based on index
  String _getMeetingColor(int index) {
    final colors = ['blue', 'green', 'orange', 'purple', 'red'];
    return colors[index % colors.length];
  }

  /// Get upcoming meetings for mentee dashboard
  Future<List<Map<String, dynamic>>> _getMenteeUpcomingMeetingsForDashboard(String menteeFirebaseUid) async {
    try {
      _initializeFirestore();
      
      if (kDebugMode) {
        print('🔥 Dashboard: Getting upcoming meetings for mentee');
        print('🔥 Dashboard: Mentee Firebase UID: $menteeFirebaseUid');
      }
      
      // First get the mentee's document to find their doc ID
      final menteeQuery = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .where('firebase_uid', isEqualTo: menteeFirebaseUid)
          .limit(1)
          .get();
          
      if (menteeQuery.docs.isEmpty) {
        if (kDebugMode) {
          print('🔥 Dashboard: No mentee document found for UID: $menteeFirebaseUid');
        }
        return [];
      }
      
      final menteeDocId = menteeQuery.docs.first.id;
      
      if (kDebugMode) {
        print('🔥 Dashboard: Found mentee doc ID: $menteeDocId');
      }
      
      final now = DateTime.now();
      
      if (kDebugMode) {
        print('🔥 Dashboard: Querying meetings where mentee_doc_id = $menteeDocId');
      }
      
      // Try compound query first
      QuerySnapshot<Map<String, dynamic>> meetingsSnapshot;
      
      try {
        meetingsSnapshot = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('meetings')
            .where('mentee_doc_id', isEqualTo: menteeDocId)
            .where('status', whereIn: ['pending', 'accepted', 'confirmed', 'cancelled', 'rejected'])
            .orderBy('start_time')
            .get();
            
        if (kDebugMode) {
          print('🔥 Dashboard: Compound query successful');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 Dashboard: Compound query failed, trying simpler query: $e');
        }
        
        // Fallback: simpler query without status filter
        meetingsSnapshot = await _firestore!
            .collection(_universityPath)
            .doc('data')
            .collection('meetings')
            .where('mentee_doc_id', isEqualTo: menteeDocId)
            .orderBy('start_time')
            .get();
      }
      
      if (kDebugMode) {
        print('🔥 Dashboard: Found ${meetingsSnapshot.docs.length} meetings for mentee');
      }
      
      final upcomingMeetings = <Map<String, dynamic>>[];
      final colors = ['blue', 'green', 'orange'];
      int colorIndex = 0;
      
      for (final doc in meetingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        
        if (kDebugMode) {
          print('🔥 Dashboard: Processing meeting ${doc.id}:');
          print('🔥 Dashboard:   - Status: $status');
          print('🔥 Dashboard:   - Start time: ${data['start_time']}');
          print('🔥 Dashboard:   - Topic: ${data['topic']}');
        }
        
        // Filter by status if compound query failed
        if (!['pending', 'accepted', 'confirmed', 'cancelled', 'rejected'].contains(status)) {
          if (kDebugMode) {
            print('🔥 Dashboard:   ❌ Skipped - invalid status');
          }
          continue;
        }
        
        // Filter out meetings hidden by the current user
        final hiddenBy = List<String>.from(data['hidden_by'] ?? []);
        if (hiddenBy.contains(menteeFirebaseUid)) {
          if (kDebugMode) {
            print('🔥 Dashboard:   ❌ Skipped - hidden by current user');
          }
          continue;
        }
        
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        final endTime = (data['end_time'] as Timestamp?)?.toDate();
        
        if (kDebugMode) {
          print('🔥 Dashboard:   - Parsed start time: $startTime');
          print('🔥 Dashboard:   - Parsed end time: $endTime');
          print('🔥 Dashboard:   - Current time: $now');
          print('🔥 Dashboard:   - Should show meeting: ${startTime != null ? _shouldShowMeeting(startTime, endTime, now) : false}');
        }
        
        if (startTime != null && _shouldShowMeeting(startTime, endTime, now)) {
          upcomingMeetings.add({
            'id': doc.id,
            'title': data['topic'] ?? 'Meeting with Mentor',
            'time': '${_formatMeetingDate(startTime)} at ${_formatMeetingTime(startTime)}',
            'location': data['location'] ?? 'TBD',
            'color': colors[colorIndex % colors.length],
            'mentorName': data['mentor_name'] ?? 'Your Mentor',
            'status': status,
            'createdBy': data['created_by'],
            'cancellationReason': data['cancellation_reason'],
            'cancelledBy': data['cancelled_by'],
          });
          colorIndex++;
          
          if (kDebugMode) {
            print('🔥 Dashboard: ✅ Added meeting: ${data['topic']} on ${_formatMeetingDate(startTime)}');
          }
        } else {
          if (kDebugMode) {
            if (startTime == null) {
              print('🔥 Dashboard:   ❌ Skipped - no start time');
            } else {
              print('🔥 Dashboard:   ❌ Skipped - meeting in the past');
            }
          }
        }
      }
      
      // If no upcoming meetings, return empty array
      // The UI will handle displaying "No upcoming meetings"
      if (upcomingMeetings.isEmpty) {
        if (kDebugMode) {
          print('🔥 Dashboard: No upcoming meetings found for mentee');
        }
        return [];
      }
      
      if (kDebugMode) {
        print('🔥 Dashboard: Returning ${upcomingMeetings.length} upcoming meetings');
      }
      
      return upcomingMeetings;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Dashboard: Error getting mentee dashboard meetings: $e');
        print('🔥 Dashboard: Stack trace: ${StackTrace.current}');
      }
      // Return empty array on error - UI will handle it
      return [];
    }
  }

  /// Format announcement timestamp for display
  String _formatAnnouncementTime(dynamic timestamp) {
    try {
      DateTime createdAt;
      if (timestamp is String) {
        createdAt = DateTime.parse(timestamp);
      } else if (timestamp is Map && timestamp['_seconds'] != null) {
        // Firestore timestamp format
        createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  /// Get announcements for coordinator dashboard
  Future<List<Map<String, dynamic>>> _getCoordinatorAnnouncements() async {
    try {
      final announcementsResult = await _cloudFunctions.getAnnouncements(
        universityPath: _universityPath,
        userType: 'coordinator',
        limit: 10,
      );
      
      if (announcementsResult['success'] == true && announcementsResult['data'] != null) {
        final List<dynamic> rawAnnouncements = announcementsResult['data'];
        return rawAnnouncements.map((announcement) {
          final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
          return {
            'id': announcementMap['id'],
            'title': announcementMap['title'],
            'content': announcementMap['content'],
            'time': _formatAnnouncementTime(announcementMap['created_at']),
            'priority': announcementMap['priority'] ?? 'none',
          };
        }).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Dashboard: Error fetching coordinator announcements: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getMenteeDashboardData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Initialize Firestore
      _initializeFirestore();

      if (kDebugMode) {
        print('🔥 Dashboard: Getting mentee data for user ${currentUser.uid}');
      }

      // Get the mentee's user document from Firestore
      final usersSnapshot = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .where('firebase_uid', isEqualTo: currentUser.uid)
          .get();

      Map<String, dynamic> menteeData = {};
      Map<String, dynamic> mentorInfo = {};

      if (usersSnapshot.docs.isNotEmpty) {
        menteeData = usersSnapshot.docs.first.data();
        
        if (kDebugMode) {
          print('🔥 Dashboard: Found mentee data: ${menteeData['name']}');
          print('🔥 Dashboard: Mentee has mentor: ${menteeData['mentor']}');
        }

        // Get mentor data if assigned
        if (kDebugMode) {
          print('🔥 Dashboard: Checking mentor field...');
          print('🔥 Dashboard: mentor field is null: ${menteeData['mentor'] == null}');
          print('🔥 Dashboard: mentor field isEmpty: ${menteeData['mentor']?.toString().isEmpty}');
        }
        
        if (menteeData['mentor'] != null && menteeData['mentor'].toString().isNotEmpty) {
          final mentorId = menteeData['mentor'].toString().trim();
          
          if (kDebugMode) {
            print('🔥 Dashboard: === MENTOR LOOKUP DEBUG ===');
            print('🔥 Dashboard: Raw mentor field value: ${menteeData['mentor']}');
            print('🔥 Dashboard: Mentor field type: ${menteeData['mentor'].runtimeType}');
            print('🔥 Dashboard: Trimmed mentor ID: "$mentorId"');
            print('🔥 Dashboard: Mentor ID length: ${mentorId.length}');
            print('🔥 Dashboard: University path: $_universityPath');
          }

          // Try to get mentor by document ID first
          try {
            // Convert spaces to underscores for document ID format
            final mentorDocId = mentorId.replaceAll(' ', '_');
            
            if (kDebugMode) {
              print('🔥 Dashboard: Converted mentor ID for document lookup: "$mentorDocId"');
            }
            
            final mentorDoc = await _firestore!
                .collection(_universityPath)
                .doc('data')
                .collection('users')
                .doc(mentorDocId)
                .get();

            if (kDebugMode) {
              print('🔥 Dashboard: Document exists: ${mentorDoc.exists}');
              if (mentorDoc.exists) {
                print('🔥 Dashboard: Mentor document data: ${mentorDoc.data()}');
              }
            }

            if (mentorDoc.exists && (mentorDoc.data()?['user_type'] == 'mentor' || mentorDoc.data()?['userType'] == 'mentor')) {
              final mentorData = mentorDoc.data()!;
              
              if (kDebugMode) {
                print('🔥 Dashboard: ✅ Found mentor by document ID!');
                print('🔥 Dashboard: Mentor name: ${mentorData['name']}');
                print('🔥 Dashboard: Mentor user_type: ${mentorData['user_type']}');
                print('🔥 Dashboard: Mentor firebase_uid: ${mentorData['firebase_uid']}');
                print('🔥 Dashboard: Mentor document fields: ${mentorData.keys.toList()}');
              }
              
              mentorInfo = {
                'id': mentorDoc.id,
                'firebase_uid': mentorData['firebase_uid'] ?? mentorDoc.id, // Add actual Firebase UID
                'name': mentorData['name'] ?? 'Unknown Mentor',
                'email': mentorData['email'] ?? '',
                'program': '${mentorData['year_major'] ?? 'Unknown Year'}, ${mentorData['department'] ?? 'Unknown Department'}',
                'yearLevel': mentorData['year_major'] ?? 'Unknown Year',
                'photoUrl': mentorData['photoUrl'] ?? '',
                'assignedDate': 'Sep 1, 2024', // TODO: Get actual assignment date
              };
              
              if (kDebugMode) {
                print('🔥 Dashboard: Mentor info created: ${mentorInfo['name']}');
              }
            } else {
              if (kDebugMode) {
                print('🔥 Dashboard: Document not found or not a mentor, trying name query...');
              }
              
              // Try querying by name since the mentor field contains a name
              final mentorQuery = await _firestore!
                  .collection(_universityPath)
                  .doc('data')
                  .collection('users')
                  .where('name', isEqualTo: mentorId)
                  .where('userType', isEqualTo: 'mentor')
                  .get();

              if (kDebugMode) {
                print('🔥 Dashboard: Name query returned ${mentorQuery.docs.length} documents');
              }

              if (mentorQuery.docs.isNotEmpty) {
                final mentorDoc = mentorQuery.docs.first;
                final mentorData = mentorDoc.data();
                
                if (kDebugMode) {
                  print('🔥 Dashboard: ✅ Found mentor by name!');
                  print('🔥 Dashboard: Mentor doc ID: ${mentorDoc.id}');
                  print('🔥 Dashboard: Mentor name: ${mentorData['name']}');
                  print('🔥 Dashboard: Mentor user_type: ${mentorData['user_type']}');
                  print('🔥 Dashboard: Mentor firebase_uid: ${mentorData['firebase_uid']}');
                }
                
                mentorInfo = {
                  'id': mentorDoc.id,
                  'firebase_uid': mentorData['firebase_uid'] ?? mentorDoc.id,
                  'name': mentorData['name'] ?? 'Unknown Mentor',
                  'email': mentorData['email'] ?? '',
                  'program': '${mentorData['year_major'] ?? 'Unknown Year'}, ${mentorData['department'] ?? 'Unknown Department'}',
                  'yearLevel': mentorData['year_major'] ?? 'Unknown Year',
                  'photoUrl': mentorData['photoUrl'] ?? '',
                  'assignedDate': 'Sep 1, 2024', // TODO: Get actual assignment date
                };
                
                if (kDebugMode) {
                  print('🔥 Dashboard: Mentor info created: ${mentorInfo['name']}');
                }
              } else {
                if (kDebugMode) {
                  print('🔥 Dashboard: ❌ No mentor found by name either');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('🔥 Dashboard: ❌ Unexpected error: $e');
              print('🔥 Dashboard: Error type: ${e.runtimeType}');
            }
          }
        } else {
          if (kDebugMode) {
            print('🔥 Dashboard: ⚠️ No mentor field or mentor field is empty');
          }
        }
      } else {
        // Fallback if no user document found
        if (kDebugMode) {
          print('🔥 Dashboard: No mentee document found, using fallback data');
        }
        menteeData = {
          'name': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Mentee',
          'department': 'Unknown Department',
          'year_major': 'Unknown Year',
        };
      }

      final menteeProfile = {
        'id': currentUser.uid,
        'name': menteeData['name'] ?? (currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Mentee'),
        'email': currentUser.email,
        'photoUrl': menteeData['photoUrl'] ?? '',
        'program': '${menteeData['year_major'] ?? 'Unknown Year'}, ${menteeData['department'] ?? 'Unknown Department'}',
        'yearLevel': menteeData['year_major'] ?? 'Unknown Year',
      };

      // If no mentor found, use default
      if (mentorInfo.isEmpty) {
        mentorInfo = {
          'id': '',
          'name': 'No Mentor Assigned',
          'email': '',
          'program': 'Please contact coordinator',
          'yearLevel': '',
          'photoUrl': '',
          'assignedDate': '',
        };
      }

      // Get real announcements from Firebase for mentees
      List<Map<String, dynamic>> menteeAnnouncementsList = [];
      try {
        final announcementsResult = await _cloudFunctions.getAnnouncements(
          universityPath: _universityPath,
          userType: 'mentee',
          limit: 10,
        );
        
        if (announcementsResult['success'] == true && announcementsResult['data'] != null) {
          final List<dynamic> rawAnnouncements = announcementsResult['data'];
          menteeAnnouncementsList = rawAnnouncements.map((announcement) {
            final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
            return {
              'id': announcementMap['id'],
              'title': announcementMap['title'],
              'content': announcementMap['content'],
              'time': _formatAnnouncementTime(announcementMap['created_at']),
              'priority': announcementMap['priority'] ?? 'none',
            };
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔥 Dashboard: Error fetching mentee announcements: $e');
        }
        // Fall back to empty list if error occurs
      }

      // Calculate progress metrics (TODO: Get from actual data)
      final progressData = {
        'checklistCompletion': 0.7,
        'meetingAttendance': 0.9,
        'completedTasks': 14,
        'totalTasks': 20,
        'attendedMeetings': 9,
        'totalMeetings': 10,
      };

      // Get recent activity (TODO: Get from actual activity logs)
      final recentActivity = [
        {
          'text': 'Completed task "Review mentor feedback"',
          'time': '2 days ago',
          'icon': 'check_circle',
          'color': 'green',
        },
        {
          'text': 'Attended meeting "Weekly Check-in"',
          'time': '4 days ago',
          'icon': 'event_available',
          'color': 'blue',
        },
        {
          'text': 'Submitted progress report',
          'time': '1 week ago',
          'icon': 'assignment_turned_in',
          'color': 'purple',
        },
      ];

      if (kDebugMode) {
        print('🔥 Dashboard: About to fetch meetings for mentee');
        print('🔥 Dashboard: currentUser.uid = ${currentUser.uid}');
        print('🔥 Dashboard: currentUser.email = ${currentUser.email}');
      }

      return {
        'menteeProfile': menteeProfile,
        'mentorInfo': mentorInfo,
        'progressData': progressData,
        'announcements': menteeAnnouncementsList,
        'upcomingMeetings': await _getMenteeUpcomingMeetingsForDashboard(currentUser.uid),
        'recentActivities': recentActivity,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching mentee dashboard data: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCoordinatorDashboardData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final usersList = await _cloudFunctions.getUsersList(
        universityPath: _universityPath,
      );

      // Debug the response structure
      if (kDebugMode) {
        print('=== getUsersList Response Debug ===');
        print('Response type: ${usersList.runtimeType}');
        print('Response keys: ${usersList.keys.toList()}');
        print('Has data key: ${usersList.containsKey('data')}');
        print('Has users key: ${usersList.containsKey('users')}');
        if (usersList.containsKey('data')) {
          print('Data type: ${usersList['data'].runtimeType}');
          print('Data is List: ${usersList['data'] is List}');
          if (usersList['data'] is List) {
            print('Data length: ${(usersList['data'] as List).length}');
          }
        }
      }

      // Handle both response formats
      final users = (usersList['data'] ?? usersList['users'] ?? []) as List<dynamic>;
      
      if (kDebugMode) {
        print('Looking for coordinator with UID: ${currentUser.uid}');
        print('Total users in database: ${users.length}');
        if (users.isNotEmpty) {
          print('Sample user fields: ${users[0].keys.toList()}');
          print('First few users:');
          for (int i = 0; i < (users.length < 3 ? users.length : 3); i++) {
            print('  User $i: id=${users[i]['id']}, email=${users[i]['email']}, firebase_uid=${users[i]['firebase_uid']}');
          }
        }
      }
      
      // Try to find user by firebase_uid, email, or id
      var coordinatorData = users.firstWhere(
        (user) => 
          user['firebase_uid'] == currentUser.uid ||
          user['email'] == currentUser.email ||
          user['id'] == currentUser.uid,
        orElse: () => null,
      );

      if (coordinatorData == null) {
        if (kDebugMode) {
          print('Warning: User not found with UID. Looking by email: ${currentUser.email}');
          final anyUserWithUid = users.firstWhere(
            (user) => 
              user['firebase_uid'] == currentUser.uid ||
              user['email'] == currentUser.email ||
              user['id'] == currentUser.uid,
            orElse: () => null,
          );
          if (anyUserWithUid != null) {
            print('Found user with role: ${anyUserWithUid['user_type'] ?? anyUserWithUid['userType']}');
            print('Using this user data for testing coordinator dashboard...');
            // For testing, use any logged-in user's data
            coordinatorData = anyUserWithUid;
          } else {
            print('No user found with email: ${currentUser.email}');
            print('For testing, using mock coordinator data with real users list...');
            // Create a mock coordinator for testing with real users data
            coordinatorData = {
              'id': 'test_coordinator',
              'name': 'Test Coordinator',
              'email': currentUser.email,
              'userType': 'coordinator',
              'firebase_uid': currentUser.uid,
            };
          }
        } else {
          throw Exception('Coordinator not found in database');
        }
      }

      // Check both user_type and userType for compatibility
      final mentors = users.where((user) => 
        user['user_type'] == 'mentor' || user['userType'] == 'mentor'
      ).toList();
      final mentees = users.where((user) => 
        user['user_type'] == 'mentee' || user['userType'] == 'mentee'
      ).toList();
      final assignedMentees = mentees.where((mentee) => mentee['mentor_id'] != null).toList();
      
      if (kDebugMode) {
        print('=== Coordinator Dashboard Data ===');
        print('Total users: ${users.length}');
        print('Total mentors: ${mentors.length}');
        print('Total mentees: ${mentees.length}');
        print('Assigned mentees: ${assignedMentees.length}');
        
        if (users.isNotEmpty) {
          print('\nFirst user structure: ${users[0].keys.toList()}');
          print('First user data: ${users[0]}');
        }
        
        if (mentees.isNotEmpty) {
          print('\nSample mentee data: ${mentees[0]}');
        }
        
        if (mentors.isNotEmpty) {
          print('\nSample mentor data: ${mentors[0]}');
        }
      }

      // Calculate real completion rate based on acknowledged mentees
      final acknowledgedMentees = mentees.where((mentee) => 
        mentee['acknowledgment_signed'] == true).length;
      final completionRate = mentees.isNotEmpty ? 
        (acknowledgedMentees / mentees.length * 100).round() : 0;

      final stats = {
        'totalMentors': mentors.length,
        'totalMentees': mentees.length,
        'activePairs': assignedMentees.length,
        'successRate': assignedMentees.isNotEmpty ? 
          (assignedMentees.length / mentees.length * 100).round() : 0,
        'completionRate': completionRate,
      };

      // Get upcoming meetings for statistics
      final upcomingMeetings = await _getCoordinatorUpcomingMeetings();
      
      // Get recent activities
      final recentActivities = await _getCoordinatorRecentActivities(mentors, mentees);

      // Get upcoming events
      final upcomingEvents = await _getCoordinatorUpcomingEvents();
      
      // Get recent messages/conversations (optional)
      final recentMessages = await _getCoordinatorRecentMessages();

      return {
        'coordinatorProfile': {
          'name': coordinatorData['name'] ?? 'Unknown Coordinator',
          'id': coordinatorData['id'],
          'email': coordinatorData['email'],
        },
        'stats': stats,
        'mentors': mentors.map((mentor) => {
          'id': mentor['id'],
          'name': mentor['name'] ?? 'Unknown',
          'department': mentor['department'],
          'year_major': mentor['year_major'],
          'assignedMentees': mentees.where((mentee) => 
            mentee['mentor_id'] == mentor['id']).length,
          'lastActive': _calculateLastActive(mentor), 
        }).toList(),
        'mentees': mentees.map((mentee) => {
          'id': mentee['id'],
          'name': mentee['name'] ?? 'Unknown',
          'department': mentee['department'],
          'year_major': mentee['year_major'],
          'mentorName': mentee['mentor_id'] != null ? 
            mentors.firstWhere((mentor) => mentor['id'] == mentee['mentor_id'], 
              orElse: () => {'name': 'Unassigned'})['name'] : 'Unassigned',
          'status': mentee['mentor_id'] != null ? 'Assigned' : 'Unassigned',
          'progress': _calculateMenteeProgress(mentee),
        }).toList(),
        'recentAssignments': assignedMentees.take(5).map((mentee) {
          try {
            final mentor = mentors.firstWhere(
              (m) => m['id'] == mentee['mentor_id'] || m['student_id'] == mentee['mentor_id'],
              orElse: () => {'name': 'Unknown Mentor'}
            );
            return {
              'menteeName': mentee['name'] ?? 'Unknown Mentee',
              'mentorName': mentor['name'] ?? 'Unknown Mentor',
              'assignedDate': _formatAssignmentDate(mentee),
              'assignedBy': 'Coordinator',
            };
          } catch (e) {
            if (kDebugMode) {
              print('Error creating assignment for mentee: $mentee');
            }
            return {
              'menteeName': mentee['name'] ?? 'Unknown Mentee',
              'mentorName': 'Unknown Mentor',
              'assignedDate': 'Recently',
              'assignedBy': 'Coordinator',
            };
          }
        }).toList(),
        'announcements': await _getCoordinatorAnnouncements(),
        'upcomingEvents': upcomingEvents,
        'recentActivities': recentActivities,
        'recentMessages': recentMessages,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching coordinator dashboard data: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableMentees() async {
    try {
      // Since mentors can't access getUsersList (coordinator only), 
      // return mock available mentees for now
      // In production, this would need a mentor-specific cloud function
      return [
        {
          'id': 'mentee_available_1',
          'name': 'Michael Brown',
          'program': '1st Year, Computer Science',
          'email': 'michael.brown@university.edu',
        },
        {
          'id': 'mentee_available_2',
          'name': 'Lisa Chen',
          'program': '2nd Year, Biology',
          'email': 'lisa.chen@university.edu',
        },
      ];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available mentees: $e');
      }
      return [];
    }
  }

  Future<bool> assignMentee(String mentorId, String menteeId) async {
    try {
      // Since assignMentor requires coordinator access, mentors can't directly assign
      // This would need to go through a coordinator or a different flow
      // For now, simulate success (in production, this might create a request for coordinator approval)
      if (kDebugMode) {
        print('Mock assignment: Mentor $mentorId requesting to assign mentee $menteeId');
      }
      
      // Simulate delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return true; // Mock success - in production this might create a pending request
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning mentee: $e');
      }
      return false;
    }
  }

  // Helper methods for coordinator dashboard
  Future<List<Map<String, dynamic>>> _getCoordinatorUpcomingMeetings() async {
    try {
      _initializeFirestore();
      if (_firestore == null) {
        return [];
      }
      
      // Query all upcoming meetings for the university
      final now = DateTime.now();
      final meetingsQuery = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('start_time', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('start_time')
          .limit(10)
          .get();

      return meetingsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'mentor_name': data['mentor_name'] ?? 'Unknown Mentor',
          'mentee_name': data['mentee_name'] ?? 'Unknown Mentee',
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'topic': data['topic'] ?? 'General Meeting',
          'location': data['location'] ?? 'TBD',
          'status': data['status'] ?? 'pending',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching coordinator upcoming meetings: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCoordinatorRecentActivities(
    List<dynamic> mentors, 
    List<dynamic> mentees
  ) async {
    try {
      _initializeFirestore();
      if (_firestore == null) {
        return [];
      }
      
      List<Map<String, dynamic>> activities = [];
      
      // Get recent meetings that have occurred
      final now = DateTime.now();
      final recentMeetingsQuery = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('meetings')
          .where('start_time', isLessThan: Timestamp.fromDate(now))
          .orderBy('start_time', descending: true)
          .limit(5)
          .get();

      for (var doc in recentMeetingsQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'completed' || data['status'] == 'confirmed') {
          activities.add({
            'type': 'meeting',
            'description': '${data['mentor_name']} met with ${data['mentee_name']}',
            'time': _formatRelativeTime(data['start_time'].toDate()),
            'icon': 'event_available',
            'color': 'green',
          });
        }
      }

      // Add recent user registrations
      final recentUsers = [...mentors, ...mentees]
        .where((user) => user['created_at'] != null)
        .toList()
        ..sort((a, b) {
          final aTime = a['created_at'] is Timestamp ? 
            a['created_at'].toDate() : DateTime.now();
          final bTime = b['created_at'] is Timestamp ? 
            b['created_at'].toDate() : DateTime.now();
          return bTime.compareTo(aTime);
        });

      for (var user in recentUsers.take(3)) {
        activities.add({
          'type': 'registration',
          'description': '${user['name']} joined as ${user['user_type']}',
          'time': user['created_at'] != null ? 
            _formatRelativeTime(user['created_at'].toDate()) : 'Recently',
          'icon': 'person_add',
          'color': 'blue',
        });
      }

      // Sort all activities by time
      activities.sort((a, b) => 0); // Keep insertion order for now
      
      return activities.take(10).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent activities: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCoordinatorUpcomingEvents() async {
    try {
      // For now, return empty list as events collection doesn't exist yet
      // In future, this would query an events collection
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching upcoming events: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCoordinatorRecentMessages() async {
    try {
      _initializeFirestore();
      if (_firestore == null) {
        return [];
      }
      
      // Query recent conversations
      final conversationsQuery = await _firestore!
          .collection(_universityPath)
          .doc('data')
          .collection('conversations')
          .orderBy('lastMessageTime', descending: true)
          .limit(5)
          .get();

      return conversationsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'participants': data['participants'] ?? [],
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': data['lastMessageTime'],
          'unreadCount': data['unreadCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent messages: $e');
      }
      return [];
    }
  }

  String _calculateLastActive(Map<String, dynamic> mentor) {
    // Check if mentor has last_active timestamp
    if (mentor['last_active'] != null) {
      try {
        final lastActive = mentor['last_active'] is Timestamp ? 
          mentor['last_active'].toDate() : DateTime.now();
        return _formatRelativeTime(lastActive);
      } catch (e) {
        return 'Recently';
      }
    }
    
    // Fallback to created_at if available
    if (mentor['created_at'] != null) {
      try {
        final createdAt = mentor['created_at'] is Timestamp ? 
          mentor['created_at'].toDate() : DateTime.now();
        final daysSince = DateTime.now().difference(createdAt).inDays;
        if (daysSince < 7) {
          return 'This week';
        } else if (daysSince < 30) {
          return 'This month';
        }
      } catch (e) {
        // Ignore
      }
    }
    
    return 'Active';
  }

  double _calculateMenteeProgress(Map<String, dynamic> mentee) {
    // Simple progress calculation based on available data
    double progress = 0.0;
    double totalFactors = 0.0;
    
    // Has mentor assigned (20%)
    if (mentee['mentor_id'] != null) {
      progress += 0.2;
      totalFactors += 0.2;
    } else {
      totalFactors += 0.2;
    }
    
    // Has signed acknowledgment (30%)
    if (mentee['acknowledgment_signed'] == true) {
      progress += 0.3;
      totalFactors += 0.3;
    } else {
      totalFactors += 0.3;
    }
    
    // Profile completeness (20%)
    if (mentee['department'] != null && mentee['year_major'] != null) {
      progress += 0.2;
      totalFactors += 0.2;
    } else {
      totalFactors += 0.2;
    }
    
    // Default 30% for ongoing participation
    progress += 0.3;
    totalFactors += 0.3;
    
    return totalFactors > 0 ? progress / totalFactors : 0.0;
  }

  String _formatAssignmentDate(Map<String, dynamic> mentee) {
    // Check if there's an assignment_date field
    if (mentee['assignment_date'] != null) {
      try {
        final assignmentDate = mentee['assignment_date'] is Timestamp ? 
          mentee['assignment_date'].toDate() : DateTime.now();
        return _formatRelativeTime(assignmentDate);
      } catch (e) {
        return 'Recently';
      }
    }
    
    // Fallback to created_at
    if (mentee['created_at'] != null) {
      try {
        final createdAt = mentee['created_at'] is Timestamp ? 
          mentee['created_at'].toDate() : DateTime.now();
        return _formatRelativeTime(createdAt);
      } catch (e) {
        return 'Recently';
      }
    }
    
    return 'Recently';
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}