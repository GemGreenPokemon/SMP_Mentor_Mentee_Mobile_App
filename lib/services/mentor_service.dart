import 'package:flutter/material.dart';

class MentorService extends ChangeNotifier {
  // Mentor Profile
  final Map<String, dynamic> mentorProfile = {
    'name': 'Sarah Martinez',
    'role': '3rd Year, Computer Science Major',
    'email': 'sarah.martinez@university.edu',
    'department': 'Computer Science',
    'joinDate': 'September 2023',
  };

  // Mentees List
  List<Map<String, dynamic>> mentees = [
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

  // Announcements
  List<Map<String, dynamic>> announcements = [
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

  // Events
  List<Map<String, dynamic>> events = [
    {
      'title': 'Mentor Training Workshop',
      'date': '2024-03-15',
      'time': '2:00 PM - 4:00 PM',
      'location': 'KL 109',
      'description': 'Required training session for all mentors.',
      'audience': 'mentors', // Can be 'mentors', 'mentees', or 'both'
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

  // Methods to update data
  void updateMenteeProgress(String menteeName, double progress) {
    final menteeIndex = mentees.indexWhere((m) => m['name'] == menteeName);
    if (menteeIndex != -1) {
      mentees[menteeIndex]['progress'] = progress;
      notifyListeners();
    }
  }

  void updateActionItem(String menteeName, String title, String description) {
    final mentee = mentees.firstWhere((m) => m['name'] == menteeName);
    final actionItem = mentee['actionItems'].firstWhere((item) => item['task'] == title);
    actionItem['task'] = title;
    actionItem['description'] = description;
    notifyListeners();
  }

  void removeActionItem(String menteeName, String title) {
    final mentee = mentees.firstWhere((m) => m['name'] == menteeName);
    mentee['actionItems'].removeWhere((item) => item['task'] == title);
    notifyListeners();
  }

  void updateMenteeGoal(String menteeName, String goalTitle, double progress) {
    final mentee = mentees.firstWhere((m) => m['name'] == menteeName);
    final goal = mentee['goals'].firstWhere((g) => g['title'] == goalTitle);
    goal['progress'] = progress;
    notifyListeners();
  }

  void completeActionItem(String menteeName, String task) {
    final mentee = mentees.firstWhere((m) => m['name'] == menteeName);
    final actionItem = mentee['actionItems'].firstWhere((a) => a['task'] == task);
    actionItem['completed'] = true;
    notifyListeners();
  }

  void addMentee(Map<String, dynamic> newMentee) {
    mentees.add(newMentee);
    notifyListeners();
  }

  void addAnnouncement(Map<String, dynamic> announcement) {
    announcements.insert(0, announcement);
    notifyListeners();
  }

  void checkInToMeeting(String menteeName, String meetingTitle) {
    final mentee = mentees.firstWhere((m) => m['name'] == menteeName);
    final meeting = mentee['upcomingMeetings'].firstWhere((m) => m['title'] == meetingTitle);
    meeting['checkedIn'] = true;
    notifyListeners();
  }

  void addEvent(Map<String, dynamic> event) {
    events.add(event);
    notifyListeners();
  }

  void updateEvent(int index, Map<String, dynamic> updatedEvent) {
    if (index >= 0 && index < events.length) {
      events[index] = updatedEvent;
      notifyListeners();
    }
  }

  void deleteEvent(int index) {
    if (index >= 0 && index < events.length) {
      events.removeAt(index);
      notifyListeners();
    }
  }
} 