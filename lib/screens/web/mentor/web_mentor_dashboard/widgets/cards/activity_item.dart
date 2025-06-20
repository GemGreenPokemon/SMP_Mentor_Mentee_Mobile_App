import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class ActivityItem extends StatelessWidget {
  final String text;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    super.key,
    required this.text,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashboardSizes.spacingSmall),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: DashboardSizes.iconSmall,
              color: color,
            ),
          ),
          const SizedBox(width: DashboardSizes.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: DashboardSizes.fontMedium,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: DashboardSizes.fontSmall,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}