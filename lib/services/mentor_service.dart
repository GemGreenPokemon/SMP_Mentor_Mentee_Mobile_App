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
    }
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
} 