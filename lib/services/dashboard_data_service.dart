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
          .where('status', whereIn: ['pending', 'accepted', 'confirmed'])
          .orderBy('start_time')
          .limit(3)
          .get();
      
      final upcomingMeetings = <Map<String, dynamic>>[];
      bool isFirst = true;
      
      for (final doc in meetings.docs) {
        final data = doc.data();
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        
        if (startTime != null && startTime.isAfter(now)) {
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
            .where('status', whereIn: ['pending', 'accepted', 'confirmed'])
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
        if (!['pending', 'accepted', 'confirmed'].contains(status)) {
          continue;
        }
        
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        
        if (startTime != null && startTime.isAfter(now)) {
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
            .where('status', whereIn: ['pending', 'accepted', 'confirmed'])
            .orderBy('start_time')
            .limit(5)
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
            .limit(10)
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
        
        // Filter by status if compound query failed
        if (!['pending', 'accepted', 'confirmed'].contains(status)) {
          continue;
        }
        
        final startTime = (data['start_time'] as Timestamp?)?.toDate();
        
        if (startTime != null && startTime.isAfter(now)) {
          upcomingMeetings.add({
            'id': doc.id,
            'title': data['topic'] ?? 'Meeting with Mentor',
            'time': '${_formatMeetingDate(startTime)} at ${_formatMeetingTime(startTime)}',
            'location': data['location'] ?? 'TBD',
            'color': colors[colorIndex % colors.length],
            'mentorName': data['mentor_name'] ?? 'Your Mentor',
            'status': status,
          });
          colorIndex++;
          
          if (kDebugMode) {
            print('🔥 Dashboard: Added meeting: ${data['topic']} on ${_formatMeetingDate(startTime)}');
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
        if (menteeData['mentor'] != null && menteeData['mentor'].toString().isNotEmpty) {
          final mentorId = menteeData['mentor'].toString().trim();
          
          if (kDebugMode) {
            print('🔥 Dashboard: Looking for mentor with ID: "$mentorId"');
          }

          // Try to get mentor by document ID first
          try {
            final mentorDoc = await _firestore!
                .collection(_universityPath)
                .doc('data')
                .collection('users')
                .doc(mentorId)
                .get();

            if (mentorDoc.exists) {
              final mentorData = mentorDoc.data()!;
              
              if (kDebugMode) {
                print('🔥 Dashboard: Found mentor by ID: ${mentorData['name']}');
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
            }
          } catch (e) {
            if (kDebugMode) {
              print('🔥 Dashboard: Error getting mentor by ID: $e');
              print('🔥 Dashboard: Trying fallback query by name...');
            }
            
            // Fallback: if document ID didn't work, try querying by name
            // This handles cases where mentor field might contain a name instead of ID
            final mentorQuery = await _firestore!
                .collection(_universityPath)
                .doc('data')
                .collection('users')
                .where('name', isEqualTo: mentorId)
                .where('user_type', isEqualTo: 'mentor')
                .get();

            if (mentorQuery.docs.isNotEmpty) {
              final mentorDoc = mentorQuery.docs.first;
              final mentorData = mentorDoc.data();
              
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
                print('🔥 Dashboard: Found mentor by name query: ${mentorInfo['name']}');
              }
            }
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

      final users = usersList['users'] as List<dynamic>? ?? [];
      final coordinatorData = users.firstWhere(
        (user) => user['firebase_uid'] == currentUser.uid,
        orElse: () => null,
      );

      if (coordinatorData == null) {
        throw Exception('Coordinator not found in database');
      }

      final mentors = users.where((user) => user['user_type'] == 'mentor').toList();
      final mentees = users.where((user) => user['user_type'] == 'mentee').toList();
      final assignedMentees = mentees.where((mentee) => mentee['mentor_id'] != null).toList();

      final stats = {
        'totalMentors': mentors.length,
        'totalMentees': mentees.length,
        'activePairs': assignedMentees.length,
        'successRate': assignedMentees.isNotEmpty ? 
          (assignedMentees.length / mentees.length * 100).round() : 0,
        'completionRate': 85, // TODO: Calculate from actual data
      };

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
          'lastActive': 'Today', // TODO: Get from actual activity data
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
          'progress': 0.65, // TODO: Calculate from actual data
        }).toList(),
        'recentAssignments': assignedMentees.take(5).map((mentee) {
          final mentor = mentors.firstWhere((m) => m['id'] == mentee['mentor_id']);
          return {
            'menteeName': mentee['name'],
            'mentorName': mentor['name'],
            'assignedDate': 'Recent', // TODO: Get actual assignment date
            'assignedBy': 'Coordinator',
          };
        }).toList(),
        'announcements': await _getCoordinatorAnnouncements(),
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
}