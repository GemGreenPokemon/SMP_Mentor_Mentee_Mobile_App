import 'package:flutter/material.dart';
import 'local_database_service.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/test_mode_manager.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/models/mentorship.dart';
import 'package:smp_mentor_mentee_mobile_app/models/meeting.dart';
import 'package:smp_mentor_mentee_mobile_app/models/announcement.dart';
import 'package:smp_mentor_mentee_mobile_app/models/mentee_goal.dart';
import 'package:smp_mentor_mentee_mobile_app/models/action_item.dart';
import 'package:smp_mentor_mentee_mobile_app/models/checklist.dart';

class MenteeService extends ChangeNotifier {
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  
  // Loading states
  bool _isLoading = false;
  bool _hasInitialized = false;
  
  // Database-loaded data cache
  Map<String, dynamic>? _dbMenteeProfile;
  Map<String, dynamic>? _dbMentorInfo;
  List<Map<String, dynamic>> _dbGoals = [];
  List<Map<String, dynamic>> _dbActionItems = [];
  List<Map<String, dynamic>> _dbUpcomingMeetings = [];
  List<Map<String, dynamic>> _dbAnnouncements = [];
  Map<String, dynamic>? _dbChecklist;
  
  // Getters for loading state
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;

  // ========== MOCK DATA (FALLBACK) ==========
  
  // Mentee Profile (Mock)
  final Map<String, dynamic> _mockMenteeProfile = {
    'name': 'Alex Chen',
    'role': '1st Year, Biology Major',
    'email': 'alex.chen@university.edu',
    'department': 'Biology',
    'joinDate': 'February 2024',
    'studentId': 'S12345678',
  };

  // Mentor Info (Mock)
  final Map<String, dynamic> _mockMentorInfo = {
    'name': 'Sarah Martinez',
    'role': '3rd Year, Computer Science Major',
    'email': 'sarah.martinez@university.edu',
    'assignedDate': 'Feb 1, 2024',
    'meetingCount': 5,
    'nextMeeting': 'Tomorrow at 2:00 PM',
  };

  // Goals (Mock)
  final List<Map<String, dynamic>> _mockGoals = [
    {'title': 'Improve study habits', 'progress': 0.8},
    {'title': 'Join Biology Club', 'progress': 1.0},
    {'title': 'Research project planning', 'progress': 0.4},
    {'title': 'Build professional network', 'progress': 0.3},
  ];

  // Action Items (Mock)
  final List<Map<String, dynamic>> _mockActionItems = [
    {
      'task': 'Complete career assessment survey',
      'dueDate': 'Tomorrow',
      'completed': false,
      'assignedBy': 'Sarah Martinez',
    },
    {
      'task': 'Review graduate school options',
      'dueDate': 'In 5 days',
      'completed': false,
      'assignedBy': 'Sarah Martinez',
    },
    {
      'task': 'Attend Biology Club meeting',
      'dueDate': 'Next Wednesday',
      'completed': true,
      'assignedBy': 'Self',
    },
  ];

  // Upcoming Meetings (Mock)
  final List<Map<String, dynamic>> _mockUpcomingMeetings = [
    {
      'title': 'Weekly Check-in',
      'date': 'Tomorrow',
      'time': '2:00 PM - 3:00 PM',
      'location': 'KL 109',
      'withMentor': 'Sarah Martinez',
    },
    {
      'title': 'Career Planning Session',
      'date': 'Next Friday',
      'time': '1:00 PM - 2:00 PM',
      'location': 'Library Room 3',
      'withMentor': 'Sarah Martinez',
    },
  ];

  // Announcements (Mock)
  final List<Map<String, dynamic>> _mockAnnouncements = [
    {
      'title': 'Mentee Workshop: Study Skills',
      'content': 'Join us for an interactive workshop on effective study strategies.',
      'time': '2 hours ago',
      'priority': 'high',
    },
    {
      'title': 'Mid-Semester Check-in Required',
      'content': 'Please schedule your mid-semester check-in with your mentor.',
      'time': '1 day ago',
      'priority': 'medium',
    },
    {
      'title': 'Resource Hub Updated',
      'content': 'New study guides and career resources have been added.',
      'time': '3 days ago',
      'priority': 'low',
    },
  ];

  // Checklist (Mock)
  final Map<String, dynamic> _mockChecklist = {
    'totalItems': 10,
    'completedItems': 6,
    'progress': 0.6,
    'categories': [
      {
        'name': 'Academic',
        'items': [
          {'title': 'Meet with academic advisor', 'completed': true},
          {'title': 'Join study group', 'completed': true},
          {'title': 'Complete mid-term evaluations', 'completed': false},
        ],
      },
      {
        'name': 'Professional Development',
        'items': [
          {'title': 'Create LinkedIn profile', 'completed': true},
          {'title': 'Attend career fair', 'completed': false},
          {'title': 'Complete resume workshop', 'completed': true},
        ],
      },
      {
        'name': 'Personal Growth',
        'items': [
          {'title': 'Join campus organization', 'completed': true},
          {'title': 'Volunteer for community service', 'completed': false},
          {'title': 'Attend wellness workshop', 'completed': true},
          {'title': 'Set semester goals', 'completed': false},
        ],
      },
    ],
  };

  // ========== DATA SOURCE SWITCHING ==========
  
  /// Returns whether we should use database or mock data
  bool get _shouldUseDatabase {
    return TestModeManager.isTestMode && 
           TestModeManager.currentTestMentee != null &&
           _hasInitialized;
  }

  /// Initialize database data if in test mode
  Future<void> initialize() async {
    if (!TestModeManager.isTestMode || TestModeManager.currentTestMentee == null) {
      _hasInitialized = true;
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadDatabaseData();
      _hasInitialized = true;
    } catch (e) {
      debugPrint('Error loading mentee data from database: $e');
      // Fall back to mock data
      _hasInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Load all data from database
  Future<void> _loadDatabaseData() async {
    final currentMentee = TestModeManager.currentTestMentee!;
    
    // Load mentee profile
    _dbMenteeProfile = await _loadMenteeProfileFromDb(currentMentee);
    
    // Load mentor info
    _dbMentorInfo = await _loadMentorInfoFromDb(currentMentee.id);
    
    // Load goals
    _dbGoals = await _loadGoalsFromDb(currentMentee.id);
    
    // Load action items
    _dbActionItems = await _loadActionItemsFromDb(currentMentee.id);
    
    // Load upcoming meetings
    _dbUpcomingMeetings = await _loadUpcomingMeetingsFromDb(currentMentee.id);
    
    // Load announcements
    _dbAnnouncements = await _loadAnnouncementsFromDb();
    
    // Load checklist (future enhancement)
    _dbChecklist = null; // Will use mock for now
  }

  // ========== PUBLIC GETTERS (DATA SOURCE SWITCHING) ==========
  
  /// Mentee profile data
  Map<String, dynamic> get menteeProfile {
    if (_shouldUseDatabase && _dbMenteeProfile != null) {
      return _dbMenteeProfile!;
    }
    return _mockMenteeProfile;
  }

  /// Mentor info
  Map<String, dynamic> get mentorInfo {
    if (_shouldUseDatabase && _dbMentorInfo != null) {
      return _dbMentorInfo!;
    }
    return _mockMentorInfo;
  }

  /// Goals list
  List<Map<String, dynamic>> get goals {
    if (_shouldUseDatabase) {
      return _dbGoals;
    }
    return _mockGoals;
  }

  /// Action items list
  List<Map<String, dynamic>> get actionItems {
    if (_shouldUseDatabase) {
      return _dbActionItems;
    }
    return _mockActionItems;
  }

  /// Upcoming meetings
  List<Map<String, dynamic>> get upcomingMeetings {
    if (_shouldUseDatabase) {
      return _dbUpcomingMeetings;
    }
    return _mockUpcomingMeetings;
  }

  /// Announcements
  List<Map<String, dynamic>> get announcements {
    if (_shouldUseDatabase) {
      return _dbAnnouncements;
    }
    return _mockAnnouncements;
  }

  /// Checklist
  Map<String, dynamic> get checklist {
    if (_shouldUseDatabase && _dbChecklist != null) {
      return _dbChecklist!;
    }
    return _mockChecklist;
  }

  // ========== DATABASE LOADING METHODS ==========
  
  /// Load mentee profile from database
  Future<Map<String, dynamic>> _loadMenteeProfileFromDb(User mentee) async {
    return {
      'name': mentee.name,
      'role': mentee.yearMajor ?? 'Unknown',
      'email': mentee.email,
      'department': mentee.department ?? 'Unknown',
      'joinDate': _formatJoinDate(mentee.createdAt),
      'studentId': mentee.studentId ?? 'Unknown',
    };
  }

  /// Load mentor info from database
  Future<Map<String, dynamic>?> _loadMentorInfoFromDb(String menteeId) async {
    try {
      // Get mentorship for this mentee
      final mentorships = await _localDb.getMentorshipsByMentee(menteeId);
      if (mentorships.isEmpty) return null;
      
      final mentorship = mentorships.first; // Assume one mentor per mentee
      final mentor = await _localDb.getUser(mentorship.mentorId);
      if (mentor == null) return null;
      
      // Count meetings
      final meetings = await _localDb.getMeetingsByMentorship(mentorship.mentorId, menteeId);
      final pastMeetings = meetings.where((m) {
        final startTime = DateTime.tryParse(m.startTime);
        return startTime != null && startTime.isBefore(DateTime.now());
      }).length;
      
      // Get next meeting
      final upcomingMeetings = meetings.where((m) {
        final startTime = DateTime.tryParse(m.startTime);
        return startTime != null && startTime.isAfter(DateTime.now());
      }).toList();
      
      upcomingMeetings.sort((a, b) {
        final aTime = DateTime.tryParse(a.startTime) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.startTime) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      
      String? nextMeeting;
      if (upcomingMeetings.isNotEmpty) {
        final meeting = upcomingMeetings.first;
        final startTime = DateTime.tryParse(meeting.startTime);
        if (startTime != null) {
          nextMeeting = '${_formatMeetingDate(startTime)} at ${_formatTime(startTime)}';
        }
      }
      
      return {
        'id': mentor.id,  // Add mentor ID
        'name': mentor.name,
        'role': mentor.yearMajor ?? 'Unknown',
        'email': mentor.email,
        'assignedDate': _formatDate(mentorship.createdAt),
        'meetingCount': pastMeetings,
        'nextMeeting': nextMeeting ?? 'No upcoming meetings',
      };
    } catch (e) {
      debugPrint('Error loading mentor info: $e');
      return null;
    }
  }

  /// Load goals from database
  Future<List<Map<String, dynamic>>> _loadGoalsFromDb(String menteeId) async {
    try {
      // Get mentorship for this mentee
      final mentorships = await _localDb.getMentorshipsByMentee(menteeId);
      if (mentorships.isEmpty) return [];
      
      final mentorship = mentorships.first;
      final goals = await _localDb.getGoalsByMentorship(mentorship.id);
      
      return goals.map((goal) => {
        'title': goal.title,
        'progress': (goal.progress / 100).clamp(0.0, 1.0),
      }).toList();
    } catch (e) {
      debugPrint('Error loading goals: $e');
      return [];
    }
  }

  /// Load action items from database
  Future<List<Map<String, dynamic>>> _loadActionItemsFromDb(String menteeId) async {
    try {
      // Get mentorship for this mentee
      final mentorships = await _localDb.getMentorshipsByMentee(menteeId);
      if (mentorships.isEmpty) return [];
      
      final mentorship = mentorships.first;
      final actionItems = await _localDb.getActionItemsByMentorship(mentorship.id);
      
      // Get mentor name
      final mentor = await _localDb.getUser(mentorship.mentorId);
      final mentorName = mentor?.name ?? 'Mentor';
      
      return actionItems.map((item) => {
        'task': item.task,
        'dueDate': _formatDueDate(item.dueDate),
        'completed': item.completed,
        'assignedBy': mentorName, // Action items are typically assigned by mentor
      }).toList();
    } catch (e) {
      debugPrint('Error loading action items: $e');
      return [];
    }
  }

  /// Helper to parse meeting time in various formats
  DateTime? _parseMeetingTime(String timeStr) {
    // First try standard ISO format
    DateTime? parsed = DateTime.tryParse(timeStr);
    if (parsed != null) return parsed;
    
    // Try to parse "YYYY-MM-DD HH:MM AM/PM" format
    if (timeStr.contains(' ')) {
      final parts = timeStr.split(' ');
      if (parts.length >= 3) {
        try {
          final datePart = parts[0];
          final timePart = parts[1];
          final amPm = parts[2].toUpperCase();
          
          final dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            final year = int.parse(dateComponents[0]);
            final month = int.parse(dateComponents[1]);
            final day = int.parse(dateComponents[2]);
            
            final timeComponents = timePart.split(':');
            if (timeComponents.length == 2) {
              var hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              
              // Convert to 24-hour format
              if (amPm == 'PM' && hour != 12) {
                hour += 12;
              } else if (amPm == 'AM' && hour == 12) {
                hour = 0;
              }
              
              return DateTime(year, month, day, hour, minute);
            }
          }
        } catch (e) {
          debugPrint('Error parsing custom time format: $e');
        }
      }
    }
    
    return null;
  }

  /// Load upcoming meetings from database
  Future<List<Map<String, dynamic>>> _loadUpcomingMeetingsFromDb(String menteeId) async {
    try {
      // Get ALL meetings for this mentee (matches schedule screen approach)
      final meetings = await _localDb.getMeetingsByMentee(menteeId);
      debugPrint('MenteeService: Loaded ${meetings.length} meetings from database for mentee $menteeId');
      
      // Include all meetings (pending, accepted, rejected) that are not too far in the past
      // EXCLUDE cancelled meetings
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7)); // Show meetings from last week
      final relevantMeetings = meetings.where((meeting) {
        // Filter out cancelled meetings
        if (meeting.status == 'cancelled') {
          debugPrint('Filtering out cancelled meeting ${meeting.id}');
          return false;
        }
        
        final startTime = _parseMeetingTime(meeting.startTime);
        
        // Debug logging for parsing issues
        if (startTime == null) {
          debugPrint('WARNING: Could not parse startTime for meeting ${meeting.id}: "${meeting.startTime}" (status: ${meeting.status})');
          // Include pending meetings even if we can't parse the time
          if (meeting.status == 'pending') {
            debugPrint('  -> Including pending meeting despite parse error');
            return true;
          }
          return false;
        }
        
        // Show all future meetings
        if (startTime.isAfter(DateTime.now())) return true;
        
        // Show past meetings if they're pending/rejected or within the last week
        if (meeting.status == 'pending' || meeting.status == 'rejected') return true;
        if (startTime.isAfter(cutoffDate)) return true;
        
        return false;
      }).toList();
      
      // Sort by start time
      relevantMeetings.sort((a, b) {
        final aTime = _parseMeetingTime(a.startTime) ?? DateTime.now();
        final bTime = _parseMeetingTime(b.startTime) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      
      // For each meeting, get the mentor's name
      final meetingsWithMentorNames = await Future.wait(
        relevantMeetings.map((meeting) async {
          final mentor = await _localDb.getUser(meeting.mentorId);
          final mentorName = mentor?.name ?? 'Mentor';
          final startTime = _parseMeetingTime(meeting.startTime) ?? DateTime.now();
          
          return {
            'id': meeting.id,
            'title': meeting.topic ?? 'Meeting',
            'date': _formatMeetingDate(startTime),
            'time': _formatMeetingTime(meeting),
            'location': meeting.location ?? 'TBD',
            'withMentor': mentorName,
            'status': meeting.status ?? 'pending',
            'startTime': meeting.startTime,
            'mentorId': meeting.mentorId,
          };
        }),
      );
      
      debugPrint('MenteeService: Returning ${meetingsWithMentorNames.length} relevant meetings for display');
      for (final meeting in meetingsWithMentorNames) {
        debugPrint('  - ${meeting['title']} on ${meeting['date']} at ${meeting['time']} (${meeting['status']})');
      }
      
      return meetingsWithMentorNames;
    } catch (e) {
      debugPrint('Error loading upcoming meetings: $e');
      return [];
    }
  }

  /// Load announcements from database
  Future<List<Map<String, dynamic>>> _loadAnnouncementsFromDb() async {
    try {
      final announcements = await _localDb.getAnnouncementsByAudience(['mentees', 'both']);
      return announcements.map((announcement) => {
        'title': announcement.title,
        'content': announcement.content,
        'time': announcement.time,
        'priority': announcement.priority ?? 'none',
      }).toList();
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      return [];
    }
  }

  // ========== UTILITY METHODS ==========
  
  String _formatJoinDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDueDate(String? dueDate) {
    if (dueDate == null) return 'No due date';
    
    try {
      final date = DateTime.tryParse(dueDate);
      if (date == null) return dueDate;
      
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      if (difference == -1) return 'Yesterday';
      if (difference > 1 && difference <= 7) return 'In $difference days';
      if (difference > 7) return 'Next ${_getDayName(date)}';
      if (difference < -1) return '${-difference} days ago';
      
      return dueDate;
    } catch (e) {
      return dueDate;
    }
  }

  String _formatMeetingDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(date.year, date.month, date.day);
    
    final difference = meetingDate.difference(today).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 1 && difference <= 7) return 'Next ${_getDayName(date)}';
    
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatMeetingTime(Meeting meeting) {
    try {
      // Handle the case where startTime might be in "YYYY-MM-DD HH:MM AM/PM" format
      DateTime? startTime = DateTime.tryParse(meeting.startTime);
      
      // If standard parsing fails, try to parse the custom format
      if (startTime == null && meeting.startTime.contains(' ')) {
        final parts = meeting.startTime.split(' ');
        if (parts.length >= 3) {
          // Extract just the time part for display
          return parts.sublist(1).join(' '); // Returns "2:00 PM" format
        }
      }
      
      final endTime = meeting.endTime != null ? DateTime.tryParse(meeting.endTime!) : null;
      
      if (startTime == null) return 'TBD';
      
      final startFormatted = _formatTime(startTime);
      if (endTime != null) {
        final endFormatted = _formatTime(endTime);
        return '$startFormatted - $endFormatted';
      }
      
      return startFormatted;
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Refresh data from database (call when test mode changes)
  Future<void> refresh() async {
    if (TestModeManager.isTestMode) {
      await initialize();
    } else {
      _hasInitialized = true;
      notifyListeners();
    }
  }
  
  /// Silent refresh - updates data without showing loading indicator
  Future<void> silentRefresh() async {
    if (!TestModeManager.isTestMode || TestModeManager.currentTestMentee == null) {
      return;
    }

    try {
      // Don't set _isLoading = true to avoid showing loading indicator
      // Clear existing data to force new references
      _dbUpcomingMeetings = [];
      await _loadDatabaseData();
      debugPrint('MenteeService silentRefresh: Loaded ${_dbUpcomingMeetings.length} meetings');
      // Notify listeners to update UI with new data
      notifyListeners();
    } catch (e) {
      debugPrint('Error during silent refresh: $e');
    }
  }

  // ========== ACTION METHODS ==========
  
  void updateGoalProgress(String goalTitle, double progress) {
    // TODO: Update in database if in test mode
    notifyListeners();
  }

  void completeActionItem(String task) {
    // TODO: Update in database if in test mode
    notifyListeners();
  }

  void updateChecklistItem(String category, String item, bool completed) {
    // TODO: Update in database if in test mode
    notifyListeners();
  }
}