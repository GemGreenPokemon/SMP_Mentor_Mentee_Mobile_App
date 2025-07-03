class CoordinatorDashboardData {
  final Map<String, dynamic>? coordinatorProfile;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> mentors;
  final List<Map<String, dynamic>> mentees;
  final List<Map<String, dynamic>> recentAssignments;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> upcomingEvents;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> recentMessages;

  CoordinatorDashboardData({
    this.coordinatorProfile,
    required this.stats,
    required this.mentors,
    required this.mentees,
    required this.recentAssignments,
    required this.announcements,
    required this.upcomingEvents,
    required this.recentActivities,
    this.recentMessages = const [],
  });

  factory CoordinatorDashboardData.fromMap(Map<String, dynamic> data) {
    return CoordinatorDashboardData(
      coordinatorProfile: data['coordinatorProfile'],
      stats: data['stats'] ?? {},
      mentors: List<Map<String, dynamic>>.from(data['mentors'] ?? []),
      mentees: List<Map<String, dynamic>>.from(data['mentees'] ?? []),
      recentAssignments: List<Map<String, dynamic>>.from(data['recentAssignments'] ?? []),
      announcements: List<Map<String, dynamic>>.from(data['announcements'] ?? []),
      upcomingEvents: List<Map<String, dynamic>>.from(data['upcomingEvents'] ?? []),
      recentActivities: List<Map<String, dynamic>>.from(data['recentActivities'] ?? []),
      recentMessages: List<Map<String, dynamic>>.from(data['recentMessages'] ?? []),
    );
  }

  factory CoordinatorDashboardData.empty() {
    return CoordinatorDashboardData(
      coordinatorProfile: null,
      stats: {},
      mentors: [],
      mentees: [],
      recentAssignments: [],
      announcements: [],
      upcomingEvents: [],
      recentActivities: [],
      recentMessages: [],
    );
  }
}