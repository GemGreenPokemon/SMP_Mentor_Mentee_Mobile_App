import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class MeetingItem extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onCheckIn;
  final Function(String meetingId)? onAccept;
  final Function(String meetingId)? onReject;
  final Function(String meetingId)? onClear;
  final String? currentUserId;

  const MeetingItem({
    super.key,
    required this.meeting,
    required this.onCheckIn,
    this.onAccept,
    this.onReject,
    this.onClear,
    this.currentUserId,
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
          if (meeting.status == 'pending' && meeting.createdBy != currentUserId && onAccept != null && onReject != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => onReject!(meeting.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardColors.errorRed,
                    side: BorderSide(color: DashboardColors.errorRed),
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
                  child: const Text('Decline'),
                ),
                const SizedBox(width: DashboardSizes.spacingSmall),
                ElevatedButton(
                  onPressed: () => onAccept!(meeting.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.successGreen,
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
                  child: const Text('Accept'),
                ),
              ],
            )
          else if (meeting.status == 'pending' && meeting.createdBy == currentUserId)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSizes.spacingMedium,
                  vertical: DashboardSizes.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: DashboardColors.warningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                  border: Border.all(
                    color: DashboardColors.warningYellow.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: DashboardColors.warningYellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Waiting for response',
                      style: DashboardTextStyles.bodySmall.copyWith(
                        color: DashboardColors.warningYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (meeting.status == 'rejected' && onClear != null)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => onClear!(meeting.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardColors.errorRed,
                  side: BorderSide(color: DashboardColors.errorRed),
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
                child: const Text('Clear'),
              ),
            )
          else if (meeting.status == 'accepted' || meeting.status == 'confirmed')
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