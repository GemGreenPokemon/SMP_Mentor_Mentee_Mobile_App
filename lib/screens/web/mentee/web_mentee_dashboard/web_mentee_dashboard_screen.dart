import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/mentee_service.dart';
import '../../../../services/auth_service.dart';
import '../../../mobile/shared/checkin_checkout_screen.dart';
import '../../shared/web_chat/web_chat_screen.dart';
import '../../shared/web_messaging/web_messaging_screen.dart';
import '../../shared/web_schedule_meeting/web_schedule_meeting_screen.dart';
import '../../shared/web_resource_hub/web_resource_hub_screen.dart';
import '../../shared/web_settings/web_settings_screen.dart';
import '../web_mentee_checklist_screen.dart';
import '../../../mobile/shared/meeting_notes_screen.dart';
import '../../shared/web_newsletter/web_newsletter_screen.dart';
import '../../../mobile/shared/announcement_screen.dart';

// Import models and utils
import 'models/dashboard_data.dart';
import 'utils/dashboard_constants.dart';

// Import widgets
import 'widgets/sidebar/dashboard_sidebar.dart';
import 'widgets/topbar/dashboard_topbar.dart';
import 'widgets/dashboard_content/dashboard_overview.dart';
import 'widgets/shared/loading_state.dart';
import 'widgets/shared/error_state.dart';

// Import refresh functionality
import 'controllers/dashboard_refresh_controller.dart';
import '../../shared/web_refresh/widgets/refreshable_container.dart';
import '../../shared/web_refresh/controllers/auto_refresh_mixin.dart';

class WebMenteeDashboardScreen extends StatefulWidget {
  const WebMenteeDashboardScreen({super.key});

  @override
  State<WebMenteeDashboardScreen> createState() => _WebMenteeDashboardScreenState();
}

class _WebMenteeDashboardScreenState extends State<WebMenteeDashboardScreen> 
    with TickerProviderStateMixin, AutoRefreshMixin {
  int _selectedIndex = 0;
  late MenteeDashboardRefreshController _refreshController;
  
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize refresh controller
    _refreshController = MenteeDashboardRefreshController();
    setupAutoRefresh(_refreshController);
    print('WebMenteeDashboardScreen: Calling initial load...');
    _refreshController.initialLoad().then((data) {
      print('WebMenteeDashboardScreen: Initial load completed. Data: ${data != null ? "Loaded" : "Failed"}');
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
    // Dispose animation controller first
    _sidebarAnimationController.dispose();
    // Then dispose refresh controller
    _refreshController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    // Update visibility based on whether we're on dashboard
    final bool wasShowingData = _selectedIndex == 0;
    final bool willShowData = index == 0;
    
    if (wasShowingData && !willShowData) {
      // Leaving dashboard - hide controller
      _refreshController.setVisibility(false);
    } else if (!wasShowingData && willShowData) {
      // Coming back to dashboard
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

  void _contactMentor() {
    final mentorInfo = _refreshController.mentorInfo ?? MentorInfo.defaultMentor();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebChatScreen(
          recipientName: mentorInfo.name,
          recipientRole: '${mentorInfo.yearLevel}, ${mentorInfo.program}',
        ),
      ),
    );
  }

  void _handleSearch() {
    // TODO: Implement global search
  }

  void _navigateToMentorChat(String mentorId) {
    final mentorInfo = _refreshController.mentorInfo ?? MentorInfo.defaultMentor();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebMessagingScreen(
          preSelectedUserId: mentorInfo.id,
          preSelectedUserName: mentorInfo.name,
          showBackButton: true,
        ),
      ),
    );
  }

  void _navigateToCheckIn() {
    final mentorInfo = _refreshController.mentorInfo ?? MentorInfo.defaultMentor();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInCheckOutScreen(
          meetingTitle: 'Weekly Check-in',
          mentorName: mentorInfo.name,
          location: 'KL 109',
          scheduledTime: 'Tomorrow at 2:00 PM',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                menteeProfile: _refreshController.menteeProfile,
              ),
          
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Premium Top Bar
                    DashboardTopbar(
                      selectedIndex: _selectedIndex,
                      onSearch: _handleSearch,
                      onContactMentor: _contactMentor,
                      refreshController: _selectedIndex == 0 ? _refreshController : null,
                    ),
                    
                    // Main content based on selected sidebar item
                    Expanded(
                      child: _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return RefreshableContainer(
          controller: _refreshController,
          builder: (context, data) => DashboardOverview(
            dashboardData: data,
            onNavigateToTab: _navigateToTab,
            onMessageMentor: _navigateToMentorChat,
            onCheckInMeeting: _navigateToCheckIn,
          ),
        );
      
      case 1: // Schedule
        return const Scaffold(
          body: WebScheduleMeetingScreen(isMentor: false),
        );
      
      case 2: // Resources
        return const Scaffold(
          body: WebResourceHubScreen(isMentor: false),
        );
      
      case 3: // Checklist
        return const Scaffold(
          body: WebMenteeChecklistScreen(),
        );
      
      case 4: // Meeting Notes
        return Scaffold(
          body: MeetingNotesScreen(
            isMentor: false,
            mentorName: _refreshController.mentorInfo?.name ?? 'Sarah Martinez',
          ),
        );
      
      case 5: // Newsletters
        return const Scaffold(
          body: WebNewsletterScreen(isMentor: false),
        );
      
      case 6: // Announcements
        return const Scaffold(
          body: AnnouncementScreen(isCoordinator: false),
        );
      
      case 7: // Settings
        return const Scaffold(
          body: WebSettingsScreen(isMentor: false),
        );
      
      default:
        return const Center(
          child: Text('Page not found'),
        );
    }
  }
}