class MenteeDashboardData {
  final MenteeProfile? menteeProfile;
  final MentorInfo? mentorInfo;
  final ProgressData progressData;
  final List<Announcement> announcements;
  final List<Meeting> upcomingMeetings;
  final List<Activity> recentActivities;

  MenteeDashboardData({
    this.menteeProfile,
    this.mentorInfo,
    required this.progressData,
    required this.announcements,
    required this.upcomingMeetings,
    required this.recentActivities,
  });

  factory MenteeDashboardData.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return MenteeDashboardData(
        progressData: ProgressData.empty(),
        announcements: [],
        upcomingMeetings: [],
        recentActivities: [],
      );
    }

    return MenteeDashboardData(
      menteeProfile: data['menteeProfile'] != null 
          ? MenteeProfile.fromMap(data['menteeProfile']) 
          : null,
      mentorInfo: data['mentorInfo'] != null 
          ? MentorInfo.fromMap(data['mentorInfo']) 
          : null,
      progressData: data['progressData'] != null
          ? ProgressData.fromMap(data['progressData'])
          : ProgressData.empty(),
      announcements: (data['announcements'] as List<dynamic>?)
          ?.map((a) => Announcement.fromMap(a))
          .toList() ?? [],
      upcomingMeetings: (data['upcomingMeetings'] as List<dynamic>?)
          ?.map((m) => Meeting.fromMap(m))
          .toList() ?? [],
      recentActivities: (data['recentActivities'] as List<dynamic>?)
          ?.map((a) => Activity.fromMap(a))
          .toList() ?? [],
    );
  }
}

class MenteeProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String program;
  final String yearLevel;

  MenteeProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.program,
    required this.yearLevel,
  });

  factory MenteeProfile.fromMap(Map<String, dynamic> map) {
    return MenteeProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Mentee',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      program: map['program'] ?? '',
      yearLevel: map['yearLevel'] ?? '',
    );
  }
}

class MentorInfo {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String program;
  final String yearLevel;
  final String assignedDate;

  MentorInfo({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.program,
    required this.yearLevel,
    required this.assignedDate,
  });

  factory MentorInfo.fromMap(Map<String, dynamic> map) {
    return MentorInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Mentor',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      program: map['program'] ?? 'Computer Science Major',
      yearLevel: map['yearLevel'] ?? '3rd Year',
      assignedDate: map['assignedDate'] ?? 'Feb 1, 2024',
    );
  }

  // Default mentor info when none is assigned
  factory MentorInfo.defaultMentor() {
    return MentorInfo(
      id: '',
      name: 'Sarah Martinez',
      email: 'sarah.martinez@example.com',
      program: 'Computer Science Major',
      yearLevel: '3rd Year',
      assignedDate: 'Feb 1, 2024',
    );
  }
}

class ProgressData {
  final double checklistCompletion;
  final double meetingAttendance;
  final int completedTasks;
  final int totalTasks;
  final int attendedMeetings;
  final int totalMeetings;

  ProgressData({
    required this.checklistCompletion,
    required this.meetingAttendance,
    required this.completedTasks,
    required this.totalTasks,
    required this.attendedMeetings,
    required this.totalMeetings,
  });

  factory ProgressData.fromMap(Map<String, dynamic> map) {
    return ProgressData(
      checklistCompletion: (map['checklistCompletion'] ?? 0.7).toDouble(),
      meetingAttendance: (map['meetingAttendance'] ?? 0.9).toDouble(),
      completedTasks: map['completedTasks'] ?? 7,
      totalTasks: map['totalTasks'] ?? 10,
      attendedMeetings: map['attendedMeetings'] ?? 9,
      totalMeetings: map['totalMeetings'] ?? 10,
    );
  }

  factory ProgressData.empty() {
    return ProgressData(
      checklistCompletion: 0.0,
      meetingAttendance: 0.0,
      completedTasks: 0,
      totalTasks: 0,
      attendedMeetings: 0,
      totalMeetings: 0,
    );
  }
}

class Meeting {
  final String id;
  final String title;
  final String time;
  final String location;
  final String color;
  final String? mentorName;
  final String? status;
  final String? createdBy;

  Meeting({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.color,
    this.mentorName,
    this.status,
    this.createdBy,
  });

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      color: map['color'] ?? 'blue',
      mentorName: map['mentorName'],
      status: map['status'],
      createdBy: map['createdBy'],
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String time;
  final String? priority;
  final String? author;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.priority,
    this.author,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      time: map['time'] ?? '',
      priority: map['priority'],
      author: map['author'],
    );
  }
}

class Activity {
  final String text;
  final String time;
  final String icon;
  final String color;

  Activity({
    required this.text,
    required this.time,
    required this.icon,
    required this.color,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      text: map['text'] ?? '',
      time: map['time'] ?? '',
      icon: map['icon'] ?? 'check_circle',
      color: map['color'] ?? 'green',
    );
  }
}