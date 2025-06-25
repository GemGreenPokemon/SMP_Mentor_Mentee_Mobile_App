import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../services/dashboard_data_service.dart';
import '../../../../../services/auth_service.dart';
import '../models/dashboard_data.dart';
import '../../../shared/web_refresh/controllers/refresh_controller.dart';
import '../../../shared/web_refresh/models/refresh_config.dart';
import '../../../shared/web_refresh/models/refresh_strategy.dart';

class MenteeDashboardRefreshController extends RefreshController<MenteeDashboardData> {
  final DashboardDataService _dataService;
  final AuthService _authService = AuthService();

  MenteeDashboardRefreshController({
    DashboardDataService? dataService,
    RefreshConfig? config,
  }) : _dataService = dataService ?? DashboardDataService(),
       super(
         config: config ?? const RefreshConfig(
           autoRefreshInterval: Duration(minutes: 5),
           staleDataThreshold: Duration(seconds: 30),
           enablePullToRefresh: true,
           enableAutoRefresh: true,
           refreshOnFocus: true,
           showLastUpdated: false,
           showRefreshIndicator: true,
           // Background refresh configuration
           backgroundStrategy: RefreshStrategy.smart,
           backgroundRefreshInterval: Duration(seconds: 15),
           keepAliveInBackground: true,
           maxBackgroundRefreshes: 50,
         ),
       ) {
    // Register for background refresh
    registerForBackgroundRefresh('mentee_dashboard');
  }

  @override
  Future<MenteeDashboardData> fetchData() async {
    try {
      print('MenteeDashboardRefreshController: Fetching dashboard data...');
      
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Fetch dashboard data
      final rawData = await _dataService.getMenteeDashboardData();
      
      if (rawData == null) {
        print('MenteeDashboardRefreshController: Dashboard data is null');
        throw Exception('Failed to load dashboard data');
      }

      print('MenteeDashboardRefreshController: Dashboard data received, converting to MenteeDashboardData object');
      // Convert to typed model
      final dashboardData = MenteeDashboardData.fromMap(rawData);
      
      print('MenteeDashboardRefreshController: Data fetched successfully. Announcements count: ${dashboardData.announcements.length}');
      return dashboardData;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Server error: ${e.message}');
    } catch (e) {
      print('Error fetching dashboard data: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  // Convenience getters
  MenteeProfile? get menteeProfile => data?.menteeProfile;
  MentorInfo? get mentorInfo => data?.mentorInfo;
  ProgressData? get progressData => data?.progressData;
  List<Announcement> get announcements => data?.announcements ?? [];
  List<Meeting> get upcomingMeetings => data?.upcomingMeetings ?? [];
  List<Activity> get recentActivities => data?.recentActivities ?? [];

  // Quick stats
  int get totalAnnouncements => announcements.length;
  int get unreadAnnouncements => announcements.where((a) => a.priority == 'high').length;
  int get todayMeetings => upcomingMeetings.where((m) => m.time.contains('Today')).length;
  double get overallProgress {
    if (progressData == null) return 0.0;
    return (progressData!.checklistCompletion + progressData!.meetingAttendance) / 2;
  }

  // Actions
  Future<void> markAnnouncementRead(String announcementId) async {
    // TODO: Implement marking announcement as read
    await Future.delayed(const Duration(milliseconds: 500));
    await refresh();
  }

  Future<void> updateProgress() async {
    // Force refresh to get latest progress data
    await refresh(silent: false);
  }
}