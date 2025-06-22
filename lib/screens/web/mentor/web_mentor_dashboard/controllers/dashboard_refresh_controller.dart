import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../services/dashboard_data_service.dart';
import '../models/dashboard_data.dart';
import '../../../shared/web_refresh/controllers/refresh_controller.dart';
import '../../../shared/web_refresh/models/refresh_config.dart';
import '../../../shared/web_refresh/models/refresh_strategy.dart';

class DashboardRefreshController extends RefreshController<DashboardData> {
  final DashboardDataService _dataService;
  
  DashboardRefreshController({
    DashboardDataService? dataService,
    RefreshConfig? config,
  }) : _dataService = dataService ?? DashboardDataService(),
       super(
         config: config ?? const RefreshConfig(
           autoRefreshInterval: Duration(minutes: 5),
           staleDataThreshold: Duration(seconds: 30), // More reasonable threshold
           enablePullToRefresh: true,
           enableAutoRefresh: true,
           refreshOnFocus: true,
           showLastUpdated: false,
           showRefreshIndicator: true,
           // Background refresh configuration
           backgroundStrategy: RefreshStrategy.smart,
           backgroundRefreshInterval: Duration(seconds: 15), // Background refresh every 15 seconds
           keepAliveInBackground: true,
           maxBackgroundRefreshes: 50,
         ),
       ) {
    // Register for background refresh
    registerForBackgroundRefresh('mentor_dashboard');
  }

  @override
  Future<DashboardData> fetchData() async {
    try {
      print('DashboardRefreshController: Fetching dashboard data...');
      final dashboardDataMap = await _dataService.getMentorDashboardData();
      
      if (dashboardDataMap == null) {
        print('DashboardRefreshController: Dashboard data is null');
        throw Exception('Failed to load dashboard data');
      }
      
      print('DashboardRefreshController: Dashboard data received, converting to DashboardData object');
      // Convert Map to DashboardData object
      final dashboardData = DashboardData.fromMap(dashboardDataMap);
      print('DashboardRefreshController: Dashboard data converted successfully. Mentees count: ${dashboardData.mentees.length}');
      return dashboardData;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Server error: ${e.message}');
    } catch (e) {
      print('Error fetching dashboard data: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  // For future use when we have section-specific refresh endpoints
  Future<void> refreshSection(String section) async {
    // Currently just refresh all data
    await refresh();
  }
}