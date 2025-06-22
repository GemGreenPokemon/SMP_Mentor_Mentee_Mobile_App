import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/activity_item.dart';

class ActivityTimeline extends StatefulWidget {
  const ActivityTimeline({super.key});

  @override
  State<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: DashboardDurations.hoverAnimation,
        curve: DashboardCurves.defaultCurve,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.01 : 1.0),
        decoration: BoxDecoration(
          color: DashboardColors.backgroundWhite,
          borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusLarge),
          boxShadow: isHovered 
              ? [
                  BoxShadow(
                    color: DashboardColors.primaryLight.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: DashboardColors.shadowMedium,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : DashboardShadows.cardShadow,
          border: Border.all(
            color: isHovered 
                ? DashboardColors.primaryLight.withOpacity(0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DashboardSizes.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.primaryLight.withOpacity(0.1),
                          DashboardColors.accentBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: DashboardColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingMedium),
                  Text(
                    DashboardStrings.recentActivity,
                    style: TextStyle(
                      fontSize: DashboardSizes.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: DashboardColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashboardSizes.spacingMedium),
              ActivityItem(
                text: 'Scheduled meeting with Alice Johnson',
                time: '2 hours ago',
                icon: Icons.event_available,
                color: Colors.blue,
                index: 0,
              ),
              const Divider(),
              ActivityItem(
                text: 'Completed Progress Report for Carlos Rodriguez',
                time: 'Yesterday',
                icon: Icons.check_circle,
                color: DashboardColors.statusGreen,
                index: 1,
              ),
              const Divider(),
              ActivityItem(
                text: 'Added new resources to the Resource Hub',
                time: '2 days ago',
                icon: Icons.folder_open,
                color: DashboardColors.statusAmber,
                index: 2,
              ),
              const Divider(),
              ActivityItem(
                text: 'Checked in for meeting with Bob Wilson',
                time: '4 days ago',
                icon: Icons.login,
                color: DashboardColors.statusPurple,
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}