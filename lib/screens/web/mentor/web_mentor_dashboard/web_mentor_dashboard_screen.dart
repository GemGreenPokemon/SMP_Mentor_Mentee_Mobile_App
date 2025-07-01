import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/mentor_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/dashboard_data_service.dart';
import '../../../../services/meeting/meeting_service.dart';
import '../../../mobile/shared/checkin_checkout_screen.dart';
import '../../shared/web_chat/web_chat_screen.dart';
import '../../shared/web_messaging/web_messaging_screen.dart';
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
  final MeetingService _meetingService = MeetingService();
  final AuthService _authService = AuthService();
  
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

  void _navigateToMenteeChat(Mentee mentee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebMessagingScreen(
          preSelectedUserId: mentee.id,
          preSelectedUserName: mentee.name,
          showBackButton: true,
        ),
      ),
    );
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

  Future<void> _acceptMeeting(String meetingId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await _meetingService.acceptMeeting(meetingId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh dashboard data
        await _refreshController.refresh();
      } else {
        throw Exception('Failed to accept meeting');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting meeting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMeeting(String meetingId) async {
    // First show confirmation dialog
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Meeting'),
        content: const Text('Are you sure you want to decline this meeting request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await _meetingService.rejectMeeting(
        meetingId,
        reason: 'Schedule conflict', // You might want to ask for a reason
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting declined'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // Refresh dashboard data
        await _refreshController.refresh();
      } else {
        throw Exception('Failed to decline meeting');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining meeting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearMeeting(String meetingId) async {
    print('🔍 _clearMeeting: Starting to clear meeting $meetingId');
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      print('🔍 _clearMeeting: Calling hideMeeting...');
      // Hide the meeting from view
      final success = await _meetingService.hideMeeting(meetingId);
      print('🔍 _clearMeeting: hideMeeting returned: $success');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        print('🔍 _clearMeeting: Success! Showing success message');
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting cleared from your list'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        print('🔍 _clearMeeting: Refreshing dashboard data...');
        // Refresh dashboard data
        await _refreshController.refresh();
        print('🔍 _clearMeeting: Dashboard refresh complete');
      } else {
        print('🔍 _clearMeeting: hideMeeting returned false');
        throw Exception('Failed to clear meeting');
      }
    } catch (e) {
      print('🔍 _clearMeeting: Error occurred: $e');
      print('🔍 _clearMeeting: Error type: ${e.runtimeType}');
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing meeting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelMeeting(String meetingId) async {
    // Show confirmation dialog with reason input
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this meeting?'),
            const SizedBox(height: 16),
            const Text(
              'Please provide a reason for cancellation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _cancellationReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {'confirm': true, 'reason': _cancellationReason}),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Meeting'),
          ),
        ],
      ),
    );

    if (result != null && result['confirm'] == true && result['reason']?.isNotEmpty == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _meetingService.cancelMeeting(meetingId, reason: result['reason']);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Refresh dashboard data
          await _refreshController.refresh();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling meeting: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _cancellationReason = '';

  Future<void> _rescheduleMeeting(String meetingId) async {
    // Navigate to schedule meeting screen with reschedule mode
    Navigator.pushNamed(
      context,
      '/schedule-meeting',
      arguments: {
        'rescheduleMode': true,
        'meetingId': meetingId,
      },
    ).then((result) async {
      if (result == true) {
        // Meeting was rescheduled successfully, refresh dashboard
        await _refreshController.refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting rescheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
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
            onAcceptMeeting: _acceptMeeting,
            onRejectMeeting: _rejectMeeting,
            onClearMeeting: _clearMeeting,
            onCancelMeeting: _cancelMeeting,
            onRescheduleMeeting: _rescheduleMeeting,
            currentUserId: _authService.currentUser?.uid,
          ),
        );
      
      case 1: // Mentees
        return RefreshableContainer(
          controller: _refreshController,
          builder: (context, data) => MenteesContent(
            dashboardData: data,
          ),
        );
      
      case 2: // Messages
        return const Scaffold(
          body: WebMessagingScreen(),
        );
      
      case 3: // Schedule
        return const Scaffold(
          body: WebScheduleMeetingScreen(isMentor: true),
        );
      
      case 4: // Reports
        return const Scaffold(
          body: WebProgressReportsScreen(),
        );
      
      case 5: // Resources
        return const Scaffold(
          body: WebResourceHubScreen(isMentor: true),
        );
      
      case 6: // Checklist
        return const Scaffold(
          body: WebChecklistScreen(isMentor: true),
        );
      
      case 7: // Newsletters
        return const Scaffold(
          body: WebNewsletterScreen(isMentor: true),
        );
      
      case 8: // Announcements
        return const Scaffold(
          body: WebAnnouncementsScreen(),
        );
      
      case 9: // Settings
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