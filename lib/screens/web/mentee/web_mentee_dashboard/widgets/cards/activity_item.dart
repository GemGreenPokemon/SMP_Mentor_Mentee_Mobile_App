import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class ActivityItem extends StatelessWidget {
  final Activity activity;

  const ActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final color = DashboardHelpers.getColorFromString(activity.color);
    final icon = DashboardHelpers.getIconFromString(activity.icon);
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingSmall),
        Expanded(
          child: Text(
            activity.text,
            style: DashboardTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          activity.time,
          style: DashboardTextStyles.caption.copyWith(
            color: DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }
}