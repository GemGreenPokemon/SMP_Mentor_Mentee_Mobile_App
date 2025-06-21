import 'package:flutter/material.dart';
import '../../models/activity_item.dart';
import '../../utils/report_constants.dart';
import '../charts/meeting_frequency_chart.dart';
import '../charts/goal_progress_chart.dart';
import '../cards/activity_item_widget.dart';

class OverviewContent extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final List<ActivityItem> recentActivities;

  const OverviewContent({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section
        Expanded(
          flex: isDesktop ? 3 : 1,
          child: Column(
            children: const [
              MeetingFrequencyChart(),
              SizedBox(height: ReportConstants.mediumPadding),
              GoalProgressChart(),
            ],
          ),
        ),
        
        if (isDesktop || isTablet) ...[
          const SizedBox(width: ReportConstants.mediumPadding),
          
          // Recent Activities Section
          SizedBox(
            width: isDesktop 
                ? ReportConstants.activityPanelWidth 
                : ReportConstants.activityPanelWidthTablet,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(ReportConstants.mediumPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: ReportConstants.subtitleTextSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ReportConstants.standardPadding),
                    ...recentActivities.map((activity) => Column(
                      children: [
                        ActivityItemWidget(activity: activity),
                        if (activity != recentActivities.last)
                          const Divider(height: ReportConstants.largePadding),
                      ],
                    )).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}