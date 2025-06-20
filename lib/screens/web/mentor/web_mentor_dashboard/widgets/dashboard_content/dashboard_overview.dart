import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import 'mentees_overview.dart';
import 'meetings_carousel.dart';
import 'announcements_preview.dart';
import 'activity_timeline.dart';

class DashboardOverview extends StatelessWidget {
  final DashboardData? dashboardData;
  final Function(int) onNavigateToTab;
  final VoidCallback onMessageMentee;
  final VoidCallback onCheckInMeeting;

  const DashboardOverview({
    super.key,
    required this.dashboardData,
    required this.onNavigateToTab,
    required this.onMessageMentee,
    required this.onCheckInMeeting,
  });

  @override
  Widget build(BuildContext context) {
    if (dashboardData == null) {
      return const Center(child: Text(DashboardStrings.noDataAvailable));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardSizes.spacingLarge),
      child: Column(
        children: [
          // Middle row - Mentees and upcoming meetings
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mentees overview
              Expanded(
                flex: 2,
                child: MenteesOverview(
                  mentees: dashboardData!.mentees,
                  onViewAll: () => onNavigateToTab(1),
                  onMessageMentee: onMessageMentee,
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingLarge),
              // Upcoming meetings
              Expanded(
                flex: 3,
                child: MeetingsCarousel(
                  onViewCalendar: () => onNavigateToTab(2),
                  onCheckIn: onCheckInMeeting,
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          // Bottom row - Announcements and Recent Activity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Announcements section
              Expanded(
                flex: 3,
                child: AnnouncementsPreview(
                  announcements: dashboardData!.announcements,
                  onViewAll: () => onNavigateToTab(7),
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingLarge),
              // Recent activity
              const Expanded(
                flex: 2,
                child: ActivityTimeline(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}