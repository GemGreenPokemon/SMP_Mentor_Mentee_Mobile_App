import 'package:flutter/material.dart';
import 'local_database_service.dart';
import '../utils/test_mode_manager.dart';
import '../models/user.dart';
import '../models/mentorship.dart';
import '../models/meeting.dart';
import '../models/announcement.dart';
import '../models/mentee_goal.dart';
import '../models/action_item.dart';
import '../models/notification.dart' as app_notification;

class MentorService extends ChangeNotifier {
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  
  // Loading states
  bool _isLoading = false;
  bool _hasInitialized = false;
  
  // Database-loaded data cache
  Map<String, dynamic>? _dbMentorProfile;
  List<Map<String, dynamic>> _dbMentees = [];
  List<Map<String, dynamic>> _dbAnnouncements = [];
  List<Map<String, dynamic>> _dbEvents = [];
  
  // Getters for loading state
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;

  // ========== MOCK DATA (FALLBACK) ==========
  
  // Mentor Profile (Mock)
  final Map<String, dynamic> _mockMentorProfile = {
    'name': 'Sarah Martinez',
    'role': '3rd Year, Computer Science Major',
    'email': 'sarah.martinez@university.edu',
    'department': 'Computer Science',
    'joinDate': 'September 2023',
  };

  // Mentees List (Mock)
  final List<Map<String, dynamic>> _mockMentees = [
    {
      'name': 'Alice Johnson',
      'program': '1st Year, Biology Major',
      'lastMeeting': '2 days ago',
      'progress': 0.6,
      'assignedBy': 'Clarissa Correa',
      'goals': [
        {'title': 'Improve study habits', 'progress': 0.8},
        {'title': 'Join Biology Club', 'progress': 1.0},
        {'title': 'Research project planning', 'progress': 0.4},
      ],
      'upcomingMeetings': [
        {
          'title': 'Weekly Check-in',
          'date': 'Tomorrow',
          'time': '2:00 PM - 3:00 PM',
          'location': 'KL 109',
          'isNext': false,
        },
        {
          'title': 'Project Brainstorm',
          'date': 'Today',
          'time': '10:00 AM - 11:00 AM',
          'location': 'Library Room 3',
          'isNext': true,
        }
      ],
      'actionItems': [
        {
          'task': 'Review project proposal',
          'dueDate': 'Tomorrow',
          'completed': false,
        }
      ],
    },
    {
      'name': 'Bob Wilson',
      'program': '2nd Year, Psychology Major',
      'lastMeeting': '1 week ago',
      'progress': 0.3,
      'assignedBy': 'You',
      'goals': [
        {'title': 'Improve presentation skills', 'progress': 0.5},
        {'title': 'Join Psychology Association', 'progress': 0.2},
        {'title': 'Research methodology study', 'progress': 0.3},
      ],
      'upcomingMeetings': [
        {
          'title': 'Progress Review',
          'date': 'Today',
          'time': '4:00 PM - 5:00 PM',
          'location': 'KL 109',
          'isNext': false,
        }
      ],
      'actionItems': [
        {
          'task': 'Submit progress report',
          'dueDate': 'In 3 days',
          'completed': false,
        }
      ],
    }
  ];

  // Announcements (Mock)
  final List<Map<String, dynamic>> _mockAnnouncements = [
    {
      'title': 'Mentor Training Session',
      'content': 'Required training session for all mentors next Tuesday.',
      'time': '1 hour ago',
      'priority': 'high',
    },
    {
      'title': 'End of Semester Review',
      'content': 'Please complete your mentee progress reports by next week.',
      'time': '1 day ago',
      'priority': 'medium',
    },
    {
      'title': 'Upcoming Workshop',
      'content': 'Join us for a career development workshop next week.',
      'time': '2 days ago',
      'priority': 'low',
    },
    {
      'title': 'Program Update',
      'content': 'New resources have been added to the resource hub.',
      'time': '3 days ago',
      'priority': 'none',
    },
    {
      'title': 'Mentorship Fair',
      'content': 'The annual mentorship fair will be held in the main hall on March 15.',
      'time': '4 days ago',
      'priority': 'none',
    }
  ];

  // Events (Mock)
  final List<Map<String, dynamic>> _mockEvents = [
    {
      'title': 'Mentor Training Workshop',
      'date': '2024-03-15',
      'time': '2:00 PM - 4:00 PM',
      'location': 'KL 109',
      'description': 'Required training session for all mentors.',
      'audience': 'mentors',
      'registeredCount': 24,
    },
    {
      'title': 'Group Mentoring Session',
      'date': '2024-03-17',
      'time': '3:00 PM - 5:00 PM',
      'location': 'KL 201',
      'description': 'Group mentoring session for all mentees.',
      'audience': 'both',
      'registeredCount': 18,
    },
    {
      'title': 'Career Development Workshop',
      'date': '2024-03-20',
      'time': '1:00 PM - 3:00 PM',
      'location': 'KL 305',
      'description': 'Workshop on resume building and interview skills.',
      'audience': 'mentees',
      'registeredCount': 32,
    },
  ];

  // ========== DATA SOURCE SWITCHING ==========
  
  /// Returns whether we should use database or mock data
  bool get _shouldUseDatabase {
    return TestModeManager.isTestMode && 
           TestModeManager.currentTestUser != null &&
           _hasInitialized;
  }

  /// Initialize database data if in test mode
  Future<void> initialize() async {
    if (!TestModeManager.isTestMode || TestModeManager.currentTestUser == null) {
      _hasInitialized = true;
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadDatabaseData();
      _hasInitialized = true;
    } catch (e) {
      debugPrint('Error loading mentor data from database: $e');
      // Fall back to mock data
      _hasInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all data from database
  Future<void> _loadDatabaseData() async {
    final currentUser = TestModeManager.currentTestUser!;
    
    // Load mentor profile
    _dbMentorProfile = await _loadMentorProfileFromDb(currentUser);
    
    // Load mentees with all related data
    _dbMentees = await _loadMenteesFromDb(currentUser.id);
    
    // Load announcements
    _dbAnnouncements = await _loadAnnouncementsFromDb();
    
    // Load events (future enhancement)
    _dbEvents = [];
  }

  // ========== PUBLIC GETTERS (DATA SOURCE SWITCHING) ==========
  
  /// Mentor profile data
  Map<String, dynamic> get mentorProfile {
    if (_shouldUseDatabase && _dbMentorProfile != null) {
      return _dbMentorProfile!;
    }
    return _mockMentorProfile;
  }

  /// List of mentees
  List<Map<String, dynamic>> get mentees {
    if (_shouldUseDatabase) {
      return _dbMentees;
    }
    return List.from(_mockMentees); // Return copy to prevent modification
  }

  /// List of announcements
  List<Map<String, dynamic>> get announcements {
    if (_shouldUseDatabase) {
      return _dbAnnouncements;
    }
    return _mockAnnouncements;
  }

  /// List of events
  List<Map<String, dynamic>> get events {
    if (_shouldUseDatabase) {
      return _dbEvents;
    }
    return _mockEvents;
  }

  // ========== DATABASE LOADING METHODS ==========
  
  /// Load mentor profile from database
  Future<Map<String, dynamic>> _loadMentorProfileFromDb(User mentor) async {
    return {
      'name': mentor.name,
      'role': mentor.yearMajor ?? 'Unknown',
      'email': mentor.email,
      'department': mentor.department ?? 'Unknown',
      'joinDate': _formatJoinDate(mentor.createdAt),
    };
  }

  /// Load mentees and related data from database
  Future<List<Map<String, dynamic>>> _loadMenteesFromDb(String mentorId) async {
    final List<Map<String, dynamic>> menteesList = [];
    
    try {
      // Get all mentorships for this mentor
      final mentorships = await _localDb.getMentorshipsByMentor(mentorId);
      
      for (final mentorship in mentorships) {
        // Get mentee user data
        final mentee = await _localDb.getUser(mentorship.menteeId);
        if (mentee == null) continue;
        
        // Get related data
        final goals = await _loadGoalsForMentorship(mentorship.id);
        final actionItems = await _loadActionItemsForMentorship(mentorship.id);
        final upcomingMeetings = await _loadUpcomingMeetingsForMentorship(mentorship);
        final lastMeeting = await _getLastMeetingInfo(mentorship.mentorId, mentorship.menteeId);
        final assignedByName = await _getAssignedByName(mentorship.assignedBy);
        
        // Build mentee data structure
        final menteeData = {
          'name': mentee.name,
          'program': mentee.yearMajor ?? 'Unknown Program',
          'lastMeeting': lastMeeting,
          'progress': (mentorship.overallProgress / 100).clamp(0.0, 1.0), // Convert to 0-1 range
          'assignedBy': assignedByName,
          'goals': goals,
          'upcomingMeetings': upcomingMeetings,
          'actionItems': actionItems,
        };
        
        menteesList.add(menteeData);
      }
    } catch (e) {
      debugPrint('Error loading mentees from database: $e');
    }
    
    return menteesList;
  }

  /// Load goals for a mentorship
  Future<List<Map<String, dynamic>>> _loadGoalsForMentorship(String mentorshipId) async {
    try {
      final goals = await _localDb.getGoalsByMentorship(mentorshipId);
      return goals.map((goal) => {
        'title': goal.title,
        'progress': (goal.progress / 100).clamp(0.0, 1.0), // Convert to 0-1 range
      }).toList();
    } catch (e) {
      debugPrint('Error loading goals: $e');
      return [];
    }
  }

  /// Load action items for a mentorship
  Future<List<Map<String, dynamic>>> _loadActionItemsForMentorship(String mentorshipId) async {
    try {
      final actionItems = await _localDb.getActionItemsByMentorship(mentorshipId);
      return actionItems.map((item) => {
        'task': item.task,
        'dueDate': _formatDueDate(item.dueDate),
        'completed': item.completed,
      }).toList();
    } catch (e) {
      debugPrint('Error loading action items: $e');
      return [];
    }
  }

  /// Load upcoming meetings for a mentorship
  Future<List<Map<String, dynamic>>> _loadUpcomingMeetingsForMentorship(Mentorship mentorship) async {
    try {
      final meetings = await _localDb.getMeetingsByMentorship(mentorship.mentorId, mentorship.menteeId);
      final upcomingMeetings = meetings.where((meeting) {
        final startTime = DateTime.tryParse(meeting.startTime);
        return startTime != null && startTime.isAfter(DateTime.now());
      }).toList();
      
      // Sort by start time
      upcomingMeetings.sort((a, b) {
        final aTime = DateTime.tryParse(a.startTime) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.startTime) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      
      // Mark the first one as next
      return upcomingMeetings.asMap().entries.map((entry) {
        final meeting = entry.value;
        final startTime = DateTime.tryParse(meeting.startTime) ?? DateTime.now();
        
        return {
          'title': meeting.topic ?? 'Meeting',
          'date': _formatMeetingDate(startTime),
          'time': _formatMeetingTime(meeting),
          'location': meeting.location ?? 'TBD',
          'isNext': entry.key == 0, // First meeting is the next one
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading upcoming meetings: $e');
      return [];
    }
  }

  /// Load announcements from database
  Future<List<Map<String, dynamic>>> _loadAnnouncementsFromDb() async {
    try {
      final announcements = await _localDb.getAnnouncementsByAudience(['mentors', 'both']);
      return announcements.map((announcement) => {
        'title': announcement.title,
        'content': announcement.content,
        'time': announcement.time, // Already formatted in database
        'priority': announcement.priority ?? 'none',
      }).toList();
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      return [];
    }
  }

  /// Get last meeting info
  Future<String> _getLastMeetingInfo(String mentorId, String menteeId) async {
    try {
      final meetings = await _localDb.getMeetingsByMentorship(mentorId, menteeId);
      final pastMeetings = meetings.where((meeting) {
        final startTime = DateTime.tryParse(meeting.startTime);
        return startTime != null && startTime.isBefore(DateTime.now());
      }).toList();
      
      if (pastMeetings.isEmpty) {
        return 'No meetings yet';
      }
      
      // Sort by start time (most recent first)
      pastMeetings.sort((a, b) {
        final aTime = DateTime.tryParse(a.startTime) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.startTime) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      final lastMeeting = pastMeetings.first;
      final meetingTime = DateTime.tryParse(lastMeeting.startTime);
      return meetingTime != null ? _getRelativeTime(meetingTime) : 'Recently';
    } catch (e) {
      debugPrint('Error getting last meeting info: $e');
      return 'Unknown';
    }
  }

  /// Get assigned by name
  Future<String> _getAssignedByName(String? assignedById) async {
    if (assignedById == null) return 'System';
    
    try {
      final user = await _localDb.getUser(assignedById);
      return user?.name ?? 'Unknown';
    } catch (e) {
      debugPrint('Error getting assigned by name: $e');
      return 'Unknown';
    }
  }

  // ========== UTILITY METHODS ==========
  
  /// Format join date
  String _formatJoinDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Format due date for action items
  String _formatDueDate(String? dueDate) {
    if (dueDate == null) return 'No due date';
    
    try {
      final date = DateTime.tryParse(dueDate);
      if (date == null) return dueDate; // Return as-is if can't parse
      
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      if (difference == -1) return 'Yesterday';
      if (difference > 1) return 'In $difference days';
      if (difference < -1) return '${-difference} days ago';
      
      return dueDate;
    } catch (e) {
      return dueDate; // Return original if parsing fails
    }
  }

  /// Format meeting date
  String _formatMeetingDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(date.year, date.month, date.day);
    
    final difference = meetingDate.difference(today).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1) return 'In $difference days';
    if (difference < -1) return '${-difference} days ago';
    
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Format meeting time
  String _formatMeetingTime(Meeting meeting) {
    try {
      final startTime = DateTime.tryParse(meeting.startTime);
      final endTime = meeting.endTime != null ? DateTime.tryParse(meeting.endTime!) : null;
      
      if (startTime == null) return 'TBD';
      
      String formatTime(DateTime time) {
        final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
      
      final startFormatted = formatTime(startTime);
      if (endTime != null) {
        final endFormatted = formatTime(endTime);
        return '$startFormatted - $endFormatted';
      }
      
      return startFormatted;
    } catch (e) {
      return 'TBD';
    }
  }

  /// Get relative time (e.g., "2 days ago")
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // ========== ORIGINAL METHODS (UPDATED FOR DATABASE SUPPORT) ==========
  
  /// Update mentee progress
  void updateMenteeProgress(String menteeName, double progress) {
    if (_shouldUseDatabase) {
      _updateMenteeProgressInDb(menteeName, progress);
    } else {
      _updateMenteeProgressInMock(menteeName, progress);
    }
    notifyListeners();
  }

  /// Update action item
  void updateActionItem(String menteeName, String title, String description) {
    if (_shouldUseDatabase) {
      _updateActionItemInDb(menteeName, title, description);
    } else {
      _updateActionItemInMock(menteeName, title, description);
    }
    notifyListeners();
  }

  /// Remove action item
  void removeActionItem(String menteeName, String title) {
    if (_shouldUseDatabase) {
      _removeActionItemInDb(menteeName, title);
    } else {
      _removeActionItemInMock(menteeName, title);
    }
    notifyListeners();
  }

  /// Update mentee goal
  void updateMenteeGoal(String menteeName, String goalTitle, double progress) {
    if (_shouldUseDatabase) {
      _updateMenteeGoalInDb(menteeName, goalTitle, progress);
    } else {
      _updateMenteeGoalInMock(menteeName, goalTitle, progress);
    }
    notifyListeners();
  }

  /// Complete action item
  void completeActionItem(String menteeName, String task) {
    if (_shouldUseDatabase) {
      _completeActionItemInDb(menteeName, task);
    } else {
      _completeActionItemInMock(menteeName, task);
    }
    notifyListeners();
  }

  /// Add mentee
  void addMentee(Map<String, dynamic> newMentee) {
    if (_shouldUseDatabase) {
      _addMenteeInDb(newMentee);
    } else {
      _mockMentees.add(newMentee);
    }
    notifyListeners();
  }

  /// Add announcement
  void addAnnouncement(Map<String, dynamic> announcement) {
    if (_shouldUseDatabase) {
      _addAnnouncementInDb(announcement);
    } else {
      _mockAnnouncements.insert(0, announcement);
    }
    notifyListeners();
  }

  /// Check in to meeting
  void checkInToMeeting(String menteeName, String meetingTitle) {
    // This would update meeting status in database
    if (_shouldUseDatabase) {
      _checkInToMeetingInDb(menteeName, meetingTitle);
    } else {
      _checkInToMeetingInMock(menteeName, meetingTitle);
    }
    notifyListeners();
  }

  /// Add event
  void addEvent(Map<String, dynamic> event) {
    if (_shouldUseDatabase) {
      _addEventInDb(event);
    } else {
      _mockEvents.add(event);
    }
    notifyListeners();
  }

  /// Update event
  void updateEvent(int index, Map<String, dynamic> updatedEvent) {
    if (_shouldUseDatabase) {
      _updateEventInDb(index, updatedEvent);
    } else {
      if (index >= 0 && index < _mockEvents.length) {
        _mockEvents[index] = updatedEvent;
      }
    }
    notifyListeners();
  }

  /// Delete event
  void deleteEvent(int index) {
    if (_shouldUseDatabase) {
      _deleteEventInDb(index);
    } else {
      if (index >= 0 && index < _mockEvents.length) {
        _mockEvents.removeAt(index);
      }
    }
    notifyListeners();
  }

  // ========== MOCK DATA UPDATE METHODS ==========
  
  void _updateMenteeProgressInMock(String menteeName, double progress) {
    final menteeIndex = _mockMentees.indexWhere((m) => m['name'] == menteeName);
    if (menteeIndex != -1) {
      _mockMentees[menteeIndex]['progress'] = progress;
    }
  }

  void _updateActionItemInMock(String menteeName, String title, String description) {
    final mentee = _mockMentees.firstWhere((m) => m['name'] == menteeName);
    final actionItem = mentee['actionItems'].firstWhere((item) => item['task'] == title);
    actionItem['task'] = title;
    actionItem['description'] = description;
  }

  void _removeActionItemInMock(String menteeName, String title) {
    final mentee = _mockMentees.firstWhere((m) => m['name'] == menteeName);
    mentee['actionItems'].removeWhere((item) => item['task'] == title);
  }

  void _updateMenteeGoalInMock(String menteeName, String goalTitle, double progress) {
    final mentee = _mockMentees.firstWhere((m) => m['name'] == menteeName);
    final goal = mentee['goals'].firstWhere((g) => g['title'] == goalTitle);
    goal['progress'] = progress;
  }

  void _completeActionItemInMock(String menteeName, String task) {
    final mentee = _mockMentees.firstWhere((m) => m['name'] == menteeName);
    final actionItem = mentee['actionItems'].firstWhere((a) => a['task'] == task);
    actionItem['completed'] = true;
  }

  void _checkInToMeetingInMock(String menteeName, String meetingTitle) {
    final mentee = _mockMentees.firstWhere((m) => m['name'] == menteeName);
    final meeting = mentee['upcomingMeetings'].firstWhere((m) => m['title'] == meetingTitle);
    meeting['checkedIn'] = true;
  }

  // ========== DATABASE UPDATE METHODS (TO BE IMPLEMENTED) ==========
  
  void _updateMenteeProgressInDb(String menteeName, double progress) {
    // TODO: Update mentorship progress in database
    debugPrint('TODO: Update progress in database for $menteeName: $progress');
  }

  void _updateActionItemInDb(String menteeName, String title, String description) {
    // TODO: Update action item in database
    debugPrint('TODO: Update action item in database for $menteeName: $title');
  }

  void _removeActionItemInDb(String menteeName, String title) {
    // TODO: Remove action item from database
    debugPrint('TODO: Remove action item from database for $menteeName: $title');
  }

  void _updateMenteeGoalInDb(String menteeName, String goalTitle, double progress) {
    // TODO: Update goal progress in database
    debugPrint('TODO: Update goal in database for $menteeName: $goalTitle');
  }

  void _completeActionItemInDb(String menteeName, String task) {
    // TODO: Mark action item as completed in database
    debugPrint('TODO: Complete action item in database for $menteeName: $task');
  }

  void _addMenteeInDb(Map<String, dynamic> newMentee) {
    // TODO: Add new mentee to database
    debugPrint('TODO: Add mentee to database: ${newMentee['name']}');
  }

  void _addAnnouncementInDb(Map<String, dynamic> announcement) {
    // TODO: Add announcement to database
    debugPrint('TODO: Add announcement to database: ${announcement['title']}');
  }

  void _checkInToMeetingInDb(String menteeName, String meetingTitle) {
    // TODO: Check in to meeting in database
    debugPrint('TODO: Check in to meeting in database for $menteeName: $meetingTitle');
  }

  void _addEventInDb(Map<String, dynamic> event) {
    // TODO: Add event to database
    debugPrint('TODO: Add event to database: ${event['title']}');
  }

  void _updateEventInDb(int index, Map<String, dynamic> updatedEvent) {
    // TODO: Update event in database
    debugPrint('TODO: Update event in database at index $index');
  }

  void _deleteEventInDb(int index) {
    // TODO: Delete event from database
    debugPrint('TODO: Delete event from database at index $index');
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
}