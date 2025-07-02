import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smp_mentor_mentee_mobile_app/services/mentor_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/dashboard_data_service.dart';

// Import models and utils
import 'models/coordinator_dashboard_data.dart';
import 'utils/dashboard_constants.dart';

// Import widgets
import 'widgets/sidebar/dashboard_sidebar.dart';
import 'widgets/topbar/dashboard_topbar.dart';
import 'widgets/dashboard_content/dashboard_overview.dart';
import 'widgets/mentors_page/mentors_content.dart';
import 'widgets/mentees_page/mentees_content.dart';
import 'widgets/matching_page/matching_content.dart';
import 'widgets/program_data_page/program_data_content.dart';
import 'widgets/shared/loading_state.dart';
import 'widgets/shared/error_state.dart';

class WebCoordinatorDashboardScreen extends StatefulWidget {
  const WebCoordinatorDashboardScreen({super.key});

  @override
  State<WebCoordinatorDashboardScreen> createState() => _WebCoordinatorDashboardScreenState();
}

class _WebCoordinatorDashboardScreenState extends State<WebCoordinatorDashboardScreen> {
  int _selectedIndex = 0;
  final DashboardDataService _dataService = DashboardDataService();
  CoordinatorDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      try {
        final data = await _dataService.getCoordinatorDashboardData();
        setState(() {
          _dashboardData = CoordinatorDashboardData.fromMap(data);
          _isLoading = false;
        });
      } catch (e) {
        // If coordinator not found or database not connected, use mock data
        if (e.toString().contains('Coordinator not found') || 
            e.toString().contains('database')) {
          setState(() {
            _dashboardData = _getMockDashboardData();
            _isLoading = false;
          });
        } else {
          throw e;
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  CoordinatorDashboardData _getMockDashboardData() {
    return CoordinatorDashboardData(
      stats: {
        'totalMentors': 12,
        'totalMentees': 36,
      },
      mentors: [
        {'name': 'Sarah Martinez', 'department': 'Computer Science', 'mentees': 3},
        {'name': 'John Davis', 'department': 'Biology', 'mentees': 2},
      ],
      mentees: [
        {'name': 'Alice Johnson', 'program': '1st Year, Biology', 'status': 'Assigned'},
        {'name': 'Bob Wilson', 'program': '2nd Year, Psychology', 'status': 'Assigned'},
      ],
      recentAssignments: [
        {
          'mentorName': 'Sarah Martinez',
          'menteeName': 'Alice Johnson',
          'assignedDate': '2 days ago',
          'coordinatorAssigned': true,
        },
      ],
      announcements: [
        {
          'title': 'Welcome to SMP Coordinator Dashboard',
          'content': 'This is a development version using mock data.',
          'date': DateTime.now().toString(),
        },
      ],
      upcomingEvents: [
        {
          'title': 'Mentor Training Workshop',
          'date': 'Tomorrow, 2:00 PM',
          'attendees': '24 Registered',
        },
      ],
      recentActivities: [
        {
          'title': 'New Survey Response',
          'description': 'From: Dr. Smith (Mentor)',
          'time': '10 minutes ago',
        },
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const LoadingState();
    }

    if (_error != null) {
      return ErrorState(
        error: _error!,
        onRetry: _loadDashboardData,
      );
    }

    switch (_selectedIndex) {
      case 0: // Dashboard
        return DashboardOverview(dashboardData: _dashboardData);
      case 1: // Mentors
        return const MentorsContent();
      case 2: // Mentees
        return const MenteesContent();
      case 3: // Matching
        return const MatchingContent();
      case 8: // Program Data
        return const ProgramDataContent();
      default:
        return DashboardOverview(dashboardData: _dashboardData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF8F9FB),
                    const Color(0xFFF0F2F5).withOpacity(0.5),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top bar
                  DashboardTopbar(
                    title: CoordinatorDashboardStrings.sidebarItems[_selectedIndex],
                  ),
                  
                  // Main content
                  Expanded(
                    child: _buildContent(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}