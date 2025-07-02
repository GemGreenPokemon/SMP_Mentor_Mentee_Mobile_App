class CoordinatorDashboardData {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> mentors;
  final List<Map<String, dynamic>> mentees;
  final List<Map<String, dynamic>> recentAssignments;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> upcomingEvents;
  final List<Map<String, dynamic>> recentActivities;

  CoordinatorDashboardData({
    required this.stats,
    required this.mentors,
    required this.mentees,
    required this.recentAssignments,
    required this.announcements,
    required this.upcomingEvents,
    required this.recentActivities,
  });

  factory CoordinatorDashboardData.fromMap(Map<String, dynamic> data) {
    return CoordinatorDashboardData(
      stats: data['stats'] ?? {},
      mentors: List<Map<String, dynamic>>.from(data['mentors'] ?? []),
      mentees: List<Map<String, dynamic>>.from(data['mentees'] ?? []),
      recentAssignments: List<Map<String, dynamic>>.from(data['recentAssignments'] ?? []),
      announcements: List<Map<String, dynamic>>.from(data['announcements'] ?? []),
      upcomingEvents: List<Map<String, dynamic>>.from(data['upcomingEvents'] ?? []),
      recentActivities: List<Map<String, dynamic>>.from(data['recentActivities'] ?? []),
    );
  }

  factory CoordinatorDashboardData.empty() {
    return CoordinatorDashboardData(
      stats: {},
      mentors: [],
      mentees: [],
      recentAssignments: [],
      announcements: [],
      upcomingEvents: [],
      recentActivities: [],
    );
  }
}