import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_layout_config.dart';
import '../shared/responsive_dashboard_grid.dart';
import '../shared/dashboard_card_container.dart';
import 'mentees_overview.dart';
import 'meetings_carousel.dart';
import 'announcements_preview.dart';
import 'activity_timeline.dart';

class DashboardOverview extends StatefulWidget {
  final DashboardData? dashboardData;
  final Function(int) onNavigateToTab;
  final Function(Mentee) onMessageMentee;
  final VoidCallback onCheckInMeeting;
  final Function(String)? onAcceptMeeting;
  final Function(String)? onRejectMeeting;
  final Function(String)? onClearMeeting;
  final String? currentUserId;

  const DashboardOverview({
    super.key,
    required this.dashboardData,
    required this.onNavigateToTab,
    required this.onMessageMentee,
    required this.onCheckInMeeting,
    this.onAcceptMeeting,
    this.onRejectMeeting,
    this.onClearMeeting,
    this.currentUserId,
  });

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  @override
  Widget build(BuildContext context) {
    if (widget.dashboardData == null) {
      return Center(
        child: const Text(DashboardStrings.noDataAvailable)
            .animate()
            .fadeIn(duration: DashboardDurations.fadeAnimation)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: DashboardCurves.smoothCurve,
            ),
      );
    }

    // Build the cards map for the responsive grid
    final cards = <String, Widget>{
      DashboardLayoutConfig.menteesCard: MenteesOverview(
        mentees: widget.dashboardData!.mentees,
        onViewAll: () => widget.onNavigateToTab(1),
        onMessageMentee: widget.onMessageMentee,
      ),
      DashboardLayoutConfig.meetingsCard: MeetingsCarousel(
        meetings: widget.dashboardData!.upcomingMeetings,
        onViewCalendar: () => widget.onNavigateToTab(2),
        onCheckIn: widget.onCheckInMeeting,
        onAcceptMeeting: widget.onAcceptMeeting,
        onRejectMeeting: widget.onRejectMeeting,
        onClearMeeting: widget.onClearMeeting,
        currentUserId: widget.currentUserId,
      ),
      DashboardLayoutConfig.announcementsCard: AnnouncementsPreview(
        announcements: widget.dashboardData!.announcements,
        onViewAll: () => widget.onNavigateToTab(7),
      ),
      DashboardLayoutConfig.activityCard: const ActivityTimeline(),
    };

    return ResponsiveDashboardGrid(
      cards: cards,
      enableAnimations: true,
    );
  }
}