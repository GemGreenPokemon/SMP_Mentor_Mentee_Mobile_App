class DashboardData {
  final MentorProfile? mentorProfile;
  final List<Mentee> mentees;
  final List<Announcement> announcements;
  final List<Meeting> upcomingMeetings;
  final List<Activity> recentActivities;

  DashboardData({
    this.mentorProfile,
    required this.mentees,
    required this.announcements,
    required this.upcomingMeetings,
    required this.recentActivities,
  });

  factory DashboardData.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return DashboardData(
        mentees: [],
        announcements: [],
        upcomingMeetings: [],
        recentActivities: [],
      );
    }

    return DashboardData(
      mentorProfile: data['mentorProfile'] != null 
          ? MentorProfile.fromMap(data['mentorProfile']) 
          : null,
      mentees: (data['mentees'] as List<dynamic>?)
          ?.map((m) => Mentee.fromMap(m))
          .toList() ?? [],
      announcements: (data['announcements'] as List<dynamic>?)
          ?.map((a) => Announcement.fromMap(a))
          .toList() ?? [],
      upcomingMeetings: (data['upcomingMeetings'] as List<dynamic>?)
          ?.map((m) => Meeting.fromMap(m))
          .toList() ?? [],
      recentActivities: [],
    );
  }
}

class MentorProfile {
  final String name;
  final String email;
  final String? photoUrl;

  MentorProfile({
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory MentorProfile.fromMap(Map<String, dynamic> map) {
    return MentorProfile(
      name: map['name'] ?? 'Mentor',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}

class Mentee {
  final String id;
  final String name;
  final String program;
  final double progress;
  final String lastMeeting;
  final String assignedBy;
  final List<Goal> goals;
  final List<Meeting> upcomingMeetings;
  final List<ActionItem> actionItems;

  Mentee({
    required this.id,
    required this.name,
    required this.program,
    required this.progress,
    required this.lastMeeting,
    required this.assignedBy,
    required this.goals,
    required this.upcomingMeetings,
    required this.actionItems,
  });

  factory Mentee.fromMap(Map<String, dynamic> map) {
    return Mentee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      program: map['program'] ?? '',
      progress: (map['progress'] ?? 0.0).toDouble(),
      lastMeeting: map['lastMeeting'] ?? 'Not met yet',
      assignedBy: map['assignedBy'] ?? '',
      goals: (map['goals'] as List<dynamic>?)
          ?.map((g) => Goal.fromMap(g))
          .toList() ?? [],
      upcomingMeetings: (map['upcomingMeetings'] as List<dynamic>?)
          ?.map((m) => Meeting.fromMap(m))
          .toList() ?? [],
      actionItems: (map['actionItems'] as List<dynamic>?)
          ?.map((a) => ActionItem.fromMap(a))
          .toList() ?? [],
    );
  }
}

class Goal {
  final String goal;
  final bool completed;

  Goal({
    required this.goal,
    required this.completed,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      goal: map['goal'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

class Meeting {
  final String id;
  final String title;
  final String menteeName;
  final String time;
  final String location;
  final String color;
  final String? startTime;
  final String? status;

  Meeting({
    required this.id,
    required this.title,
    required this.menteeName,
    required this.time,
    required this.location,
    required this.color,
    this.startTime,
    this.status,
  });

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      menteeName: map['menteeName'] ?? 'Unknown',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      color: map['color'] ?? 'blue',
      startTime: map['startTime'],
      status: map['status'],
    );
  }
}

class ActionItem {
  final String item;
  final String dueDate;

  ActionItem({
    required this.item,
    required this.dueDate,
  });

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      item: map['item'] ?? '',
      dueDate: map['dueDate'] ?? '',
    );
  }
}

class Announcement {
  final String title;
  final String content;
  final String time;
  final String? priority;

  Announcement({
    required this.title,
    required this.content,
    required this.time,
    this.priority,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      time: map['time'] ?? '',
      priority: map['priority'],
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
}