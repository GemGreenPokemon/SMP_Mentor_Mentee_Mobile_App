import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class AnnouncementItem extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementItem({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = DashboardHelpers.getPriorityColor(announcement.priority);
    final hasPriority = announcement.priority != null && announcement.priority != 'none';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashboardSizes.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasPriority 
                      ? priorityColor.withOpacity(0.1)
                      : DashboardColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    hasPriority ? Icons.priority_high : Icons.campaign,
                    color: hasPriority ? priorityColor : DashboardColors.accentBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingSmall + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: DashboardTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasPriority)
                          Container(
                            margin: const EdgeInsets.only(left: DashboardSizes.spacingSmall),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: priorityColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              DashboardHelpers.getPriorityText(announcement.priority),
                              style: DashboardTextStyles.caption.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.content,
                      style: DashboardTextStyles.bodySmall.copyWith(
                        color: DashboardColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.time,
                      style: DashboardTextStyles.caption.copyWith(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}