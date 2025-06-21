import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../services/dashboard_data_service.dart';
import '../models/dashboard_data.dart';
import '../../../shared/web_refresh/controllers/refresh_controller.dart';
import '../../../shared/web_refresh/models/refresh_config.dart';

class DashboardRefreshController extends RefreshController<DashboardData> {
  final DashboardDataService _dataService;
  
  DashboardRefreshController({
    DashboardDataService? dataService,
    RefreshConfig? config,
  }) : _dataService = dataService ?? DashboardDataService(),
       super(
         config: config ?? const RefreshConfig(
           autoRefreshInterval: Duration(minutes: 5),
           staleDataThreshold: Duration(minutes: 3),
           enablePullToRefresh: true,
           enableAutoRefresh: true,
           refreshOnFocus: true,
           showLastUpdated: true,
           showRefreshIndicator: true,
         ),
       );

  @override
  Future<DashboardData> fetchData() async {
    try {
      final dashboardDataMap = await _dataService.getMentorDashboardData();
      
      if (dashboardDataMap == null) {
        throw Exception('Failed to load dashboard data');
      }
      
      // Convert Map to DashboardData object
      return DashboardData.fromMap(dashboardDataMap);
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