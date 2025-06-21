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

class WebMentorDashboardScreen extends StatefulWidget {
  const WebMentorDashboardScreen({super.key});

  @override
  State<WebMentorDashboardScreen> createState() => _WebMentorDashboardScreenState();
}

class _WebMentorDashboardScreenState extends State<WebMentorDashboardScreen> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final DashboardDataService _dataService = DashboardDataService();
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;
  
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
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
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      
      final data = await _dataService.getMentorDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = DashboardData.fromMap(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToTab(int index) {
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
    if (_dashboardData != null && _dashboardData!.mentees.isNotEmpty) {
      final mentee = _dashboardData!.mentees.first;
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
      body: Row(
        children: [
          // Premium Sidebar
          DashboardSidebar(
            animation: _sidebarAnimation,
            selectedIndex: _selectedIndex,
            onItemSelected: _navigateToTab,
            mentorProfile: _dashboardData?.mentorProfile,
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
                ),
                
                // Main content based on selected sidebar item
                Expanded(
                  child: _buildContent(context, mentorService),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MentorService mentorService) {
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
        return DashboardOverview(
          dashboardData: _dashboardData,
          onNavigateToTab: _navigateToTab,
          onMessageMentee: _navigateToMenteeChat,
          onCheckInMeeting: _navigateToCheckIn,
        );
      
      case 1: // Mentees
        return MenteesContent(
          dashboardData: _dashboardData,
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