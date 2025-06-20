import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class AnnouncementItem extends StatelessWidget {
  final String title;
  final String content;
  final String time;
  final String? priority;

  const AnnouncementItem({
    super.key,
    required this.title,
    required this.content,
    required this.time,
    this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final hasPriority = priority != null && priority != 'none';
    final priorityColor = DashboardHelpers.getPriorityColor(priority);
    final priorityText = DashboardHelpers.getPriorityText(priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: DashboardSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPriority ? Icons.priority_high : Icons.campaign,
                color: hasPriority ? priorityColor : DashboardColors.accentBlueLight,
                size: DashboardSizes.iconMedium,
              ),
              const SizedBox(width: DashboardSizes.spacingSmall),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: DashboardSizes.fontLarge,
                        ),
                      ),
                    ),
                    if (hasPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: priorityColor,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          priorityText,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: DashboardSizes.fontMedium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: DashboardSizes.fontSmall,
            ),
          ),
        ],
      ),
    );
  }
}