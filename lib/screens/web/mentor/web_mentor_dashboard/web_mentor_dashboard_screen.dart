import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/mentor_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/dashboard_data_service.dart';
import '../../../mobile/shared/checkin_checkout_screen.dart';
import '../../shared/web_chat/web_chat_screen.dart';
import '../../shared/web_schedule_meeting/web_schedule_meeting_screen.dart';
import '../../shared/web_progress_reports/web_progress_reports_screen.dart';
import '../../shared/web_resource_hub/web_resource_hub_screen.dart';
import '../../shared/web_settings/web_settings_screen.dart';
import '../../shared/web_checklist/web_checklist_screen.dart';
import '../../shared/web_newsletter/web_newsletter_screen.dart';
import '../../shared/web_announcements/web_announcements_screen.dart';

// Import models and utils
import 'models/dashboard_data.dart';
import 'utils/dashboard_constants.dart';

// Import widgets
import 'widgets/sidebar/dashboard_sidebar.dart';
import 'widgets/topbar/dashboard_topbar.dart';
import 'widgets/dashboard_content/dashboard_overview.dart';
import 'widgets/mentees_page/mentees_content.dart';
import 'widgets/shared/loading_state.dart';
import 'widgets/shared/error_state.dart';

// Import refresh functionality
import 'controllers/dashboard_refresh_controller.dart';
import '../../shared/web_refresh/widgets/refreshable_container.dart';
import '../../shared/web_refresh/controllers/auto_refresh_mixin.dart';

class WebMentorDashboardScreen extends StatefulWidget {
  const WebMentorDashboardScreen({super.key});

  @override
  State<WebMentorDashboardScreen> createState() => _WebMentorDashboardScreenState();
}

class _WebMentorDashboardScreenState extends State<WebMentorDashboardScreen> 
    with TickerProviderStateMixin, AutoRefreshMixin {
  int _selectedIndex = 0;
  late DashboardRefreshController _refreshController;
  
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize refresh controller
    _refreshController = DashboardRefreshController();
    setupAutoRefresh(_refreshController);
    print('WebMentorDashboardScreen: Calling initial load...');
    _refreshController.initialLoad().then((data) {
      print('WebMentorDashboardScreen: Initial load completed. Data: ${data != null ? "Loaded" : "Failed"}');
    });
    
    // Initialize animations
    _sidebarAnimationController = AnimationController(
      duration: DashboardDurations.sidebarAnimation,
      vsync: this,
    );
    
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    _sidebarAnimationController.forward();
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }


  void _navigateToTab(int index) {
    // Update visibility based on whether we're on dashboard or mentees tab
    final bool wasShowingData = _selectedIndex == 0 || _selectedIndex == 1;
    final bool willShowData = index == 0 || index == 1;
    
    if (wasShowingData && !willShowData) {
      // Leaving dashboard/mentees - hide controller
      _refreshController.setVisibility(false);
    } else if (!wasShowingData && willShowData) {
      // Coming back to dashboard/mentees
      _refreshController.setVisibility(true);
    }
    
    // Handle refresh when clicking dashboard tab
    if (index == 0) {
      if (_selectedIndex == 0) {
        // Already on dashboard, clicking it again - refresh with animation
        _refreshController.refresh(silent: false);
      } else if (_selectedIndex != 0) {
        // Coming from another tab to dashboard
        // Check if data is stale before refreshing
        if (_refreshController.state.shouldAutoRefresh(_refreshController.config.staleDataThreshold)) {
          _refreshController.refresh(silent: false);
        }
      }
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _contactCoordinator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebChatScreen(
          recipientName: 'Clarissa Correa',
          recipientRole: 'SMP Program Coordinator',
        ),
      ),
    );
  }

  void _handleSearch() {
    // TODO: Implement global search
  }

  void _navigateToMenteeChat() {
    final data = _refreshController.data;
    if (data != null && data.mentees.isNotEmpty) {
      final mentee = data.mentees.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebChatScreen(
            recipientName: mentee.name,
            recipientRole: mentee.program,
          ),
        ),
      );
    }
  }

  void _navigateToCheckIn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckInCheckOutScreen(
          meetingTitle: 'Weekly Check-in',
          mentorName: 'Sarah Martinez',
          location: 'KL 109',
          scheduledTime: 'Tomorrow at 2:00 PM',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    return Scaffold(
      backgroundColor: DashboardColors.backgroundMain,
      body: ListenableBuilder(
        listenable: _refreshController,
        builder: (context, _) {
          return Row(
            children: [
              // Premium Sidebar
              DashboardSidebar(
                animation: _sidebarAnimation,
                selectedIndex: _selectedIndex,
                onItemSelected: _navigateToTab,
                mentorProfile: _refreshController.data?.mentorProfile,
              ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Premium Top Bar
                DashboardTopbar(
                  selectedIndex: _selectedIndex,
                  onSearch: _handleSearch,
                  onContactCoordinator: _contactCoordinator,
                  refreshController: _selectedIndex == 0 ? _refreshController : null,
                ),
                
                // Main content based on selected sidebar item
                Expanded(
                  child: _buildContent(context, mentorService),
                ),
              ],
            ),
          ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, MentorService mentorService) {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return RefreshableContainer(
          controller: _refreshController,
          builder: (context, data) => DashboardOverview(
            dashboardData: data,
            onNavigateToTab: _navigateToTab,
            onMessageMentee: _navigateToMenteeChat,
            onCheckInMeeting: _navigateToCheckIn,
          ),
        );
      
      case 1: // Mentees
        return RefreshableContainer(
          controller: _refreshController,
          builder: (context, data) => MenteesContent(
            dashboardData: data,
          ),
        );
      
      case 2: // Schedule
        return const Scaffold(
          body: WebScheduleMeetingScreen(isMentor: true),
        );
      
      case 3: // Reports
        return const Scaffold(
          body: WebProgressReportsScreen(),
        );
      
      case 4: // Resources
        return const Scaffold(
          body: WebResourceHubScreen(isMentor: true),
        );
      
      case 5: // Checklist
        return const Scaffold(
          body: WebChecklistScreen(isMentor: true),
        );
      
      case 6: // Newsletters
        return const Scaffold(
          body: WebNewsletterScreen(isMentor: true),
        );
      
      case 7: // Announcements
        return const Scaffold(
          body: WebAnnouncementsScreen(),
        );
      
      case 8: // Settings
        return const Scaffold(
          body: WebSettingsScreen(isMentor: true),
        );
      
      default:
        return const Center(
          child: Text('Page not found'),
        );
    }
  }
}