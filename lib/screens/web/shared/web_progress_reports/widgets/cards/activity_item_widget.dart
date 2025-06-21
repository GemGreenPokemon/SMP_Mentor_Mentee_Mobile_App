import 'package:flutter/material.dart';
import '../../models/activity_item.dart';
import '../../utils/report_constants.dart';

class ActivityItemWidget extends StatelessWidget {
  final ActivityItem activity;

  const ActivityItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(ReportConstants.tinyPadding),
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            activity.icon,
            size: 20,
            color: activity.color,
          ),
        ),
        const SizedBox(width: ReportConstants.smallPadding / 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.activity,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ReportConstants.bodyTextSize,
                ),
              ),
              Text(
                activity.time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: ReportConstants.captionTextSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}