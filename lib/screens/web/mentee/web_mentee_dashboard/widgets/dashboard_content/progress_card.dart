import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';
import '../shared/dashboard_card_container.dart';
import '../cards/activity_item.dart';

class ProgressCard extends StatelessWidget {
  final ProgressData progressData;
  final List<Activity> recentActivities;

  const ProgressCard({
    super.key,
    required this.progressData,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: DashboardTextStyles.h4,
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  'Checklist Completion',
                  progressData.checklistCompletion,
                  DashboardColors.primaryDark,
                  '${progressData.completedTasks}/${progressData.totalTasks} tasks',
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingLarge),
              Expanded(
                child: _buildProgressIndicator(
                  'Meeting Attendance',
                  progressData.meetingAttendance,
                  DashboardColors.successGreen,
                  '${progressData.attendedMeetings}/${progressData.totalMeetings} meetings',
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          Text(
            'Recent Activity',
            style: DashboardTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DashboardSizes.spacingSmall),
          if (recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DashboardSizes.spacingMedium),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: DashboardTextStyles.body.copyWith(
                    color: DashboardColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...recentActivities.take(2).map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall),
              child: ActivityItem(activity: activity),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    double value,
    Color color,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DashboardTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: DashboardColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DashboardSizes.spacingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subtitle,
              style: DashboardTextStyles.bodySmall.copyWith(
                color: DashboardColors.textSecondary,
              ),
            ),
            Text(
              DashboardHelpers.getProgressPercentage(value),
              style: DashboardTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}