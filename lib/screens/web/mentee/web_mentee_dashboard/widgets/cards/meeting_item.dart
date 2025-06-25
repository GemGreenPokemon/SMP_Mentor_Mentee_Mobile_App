import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class MeetingItem extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onCheckIn;

  const MeetingItem({
    super.key,
    required this.meeting,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final color = DashboardHelpers.getColorFromString(meeting.color);
    
    return Container(
      padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: DashboardColors.borderLight),
        borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingSmall),
              Expanded(
                child: Text(
                  meeting.title,
                  style: DashboardTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingSmall),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: DashboardColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meeting.time,
                      style: DashboardTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: DashboardColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meeting.location,
                        style: DashboardTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DashboardSizes.spacingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSizes.spacingMedium,
                  vertical: DashboardSizes.spacingSmall,
                ),
                minimumSize: const Size(0, 32),
                textStyle: DashboardTextStyles.bodySmall,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                ),
              ),
              child: const Text('Check In'),
            ),
          ),
        ],
      ),
    );
  }
}