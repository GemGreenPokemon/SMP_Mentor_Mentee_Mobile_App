import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';
import '../../utils/dashboard_layout_config.dart';
import '../shared/loading_state.dart';
import '../shared/error_state.dart';
import 'mentor_info_card.dart';
import 'progress_card.dart';
import 'announcements_preview.dart';
import 'meetings_preview.dart';

class DashboardOverview extends StatelessWidget {
  final MenteeDashboardData? dashboardData;
  final Function(int) onNavigateToTab;
  final Function(String) onMessageMentor;
  final VoidCallback onCheckInMeeting;
  final Function(String meetingId)? onAcceptMeeting;
  final Function(String meetingId)? onRejectMeeting;
  final Function(String meetingId)? onClearMeeting;
  final Function(String meetingId)? onCancelMeeting;
  final String? currentUserId;

  const DashboardOverview({
    super.key,
    required this.dashboardData,
    required this.onNavigateToTab,
    required this.onMessageMentor,
    required this.onCheckInMeeting,
    this.onAcceptMeeting,
    this.onRejectMeeting,
    this.onClearMeeting,
    this.onCancelMeeting,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = DashboardLayoutConfig.getScreenPadding(screenWidth);
        
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row - Mentor card and Progress card
              _buildTopSection(context, screenWidth),
              
              const SizedBox(height: DashboardSizes.spacingLarge),
              
              // Middle row - Announcements and Upcoming Meetings
              _buildMiddleSection(context, screenWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSection(BuildContext context, double screenWidth) {
    final isTablet = DashboardLayoutConfig.isTablet(context);
    
    if (isTablet) {
      return Column(
        children: [
          MentorInfoCard(
            mentorInfo: dashboardData!.mentorInfo ?? MentorInfo.defaultMentor(),
            onMessage: () => onMessageMentor(dashboardData!.mentorInfo?.id ?? ''),
            onSchedule: () => onNavigateToTab(1), // Navigate to Schedule tab
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          ProgressCard(
            progressData: dashboardData!.progressData,
            recentActivities: dashboardData!.recentActivities,
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: DashboardLayoutConfig.getMentorCardFlex(screenWidth),
          child: MentorInfoCard(
            mentorInfo: dashboardData!.mentorInfo ?? MentorInfo.defaultMentor(),
            onMessage: () => onMessageMentor(dashboardData!.mentorInfo?.id ?? ''),
            onSchedule: () => onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingLarge),
        Expanded(
          flex: DashboardLayoutConfig.getProgressCardFlex(screenWidth),
          child: ProgressCard(
            progressData: dashboardData!.progressData,
            recentActivities: dashboardData!.recentActivities,
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleSection(BuildContext context, double screenWidth) {
    final isTablet = DashboardLayoutConfig.isTablet(context);
    
    if (isTablet) {
      return Column(
        children: [
          AnnouncementsPreview(
            announcements: dashboardData!.announcements,
            onViewAll: () => onNavigateToTab(6), // Navigate to Announcements tab
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          MeetingsPreview(
            meetings: dashboardData!.upcomingMeetings,
            onViewCalendar: () => onNavigateToTab(1), // Navigate to Schedule tab
            onCheckIn: onCheckInMeeting,
            onAcceptMeeting: onAcceptMeeting,
            onRejectMeeting: onRejectMeeting,
            onClearMeeting: onClearMeeting,
            onCancelMeeting: onCancelMeeting,
            currentUserId: currentUserId,
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: DashboardLayoutConfig.getAnnouncementCardFlex(screenWidth),
          child: AnnouncementsPreview(
            announcements: dashboardData!.announcements,
            onViewAll: () => onNavigateToTab(6),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingLarge),
        Expanded(
          flex: DashboardLayoutConfig.getMeetingCardFlex(screenWidth),
          child: MeetingsPreview(
            meetings: dashboardData!.upcomingMeetings,
            onViewCalendar: () => onNavigateToTab(1),
            onCheckIn: onCheckInMeeting,
            onAcceptMeeting: onAcceptMeeting,
            onRejectMeeting: onRejectMeeting,
            onClearMeeting: onClearMeeting,
            onCancelMeeting: onCancelMeeting,
            currentUserId: currentUserId,
          ),
        ),
      ],
    );
  }
}