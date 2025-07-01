import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../shared/dashboard_card_container.dart';
import '../cards/meeting_item.dart';

class MeetingsPreview extends StatelessWidget {
  final List<Meeting> meetings;
  final VoidCallback onViewCalendar;
  final VoidCallback onCheckIn;
  final Function(String meetingId)? onAcceptMeeting;
  final Function(String meetingId)? onRejectMeeting;
  final Function(String meetingId)? onClearMeeting;
  final Function(String meetingId)? onCancelMeeting;
  final String? currentUserId;

  const MeetingsPreview({
    super.key,
    required this.meetings,
    required this.onViewCalendar,
    required this.onCheckIn,
    this.onAcceptMeeting,
    this.onRejectMeeting,
    this.onClearMeeting,
    this.onCancelMeeting,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Meetings',
                style: DashboardTextStyles.h4,
              ),
              TextButton(
                onPressed: onViewCalendar,
                child: Text(
                  'View Calendar',
                  style: DashboardTextStyles.button.copyWith(
                    color: DashboardColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          if (meetings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DashboardSizes.spacingXLarge),
              child: Center(
                child: Text(
                  'No upcoming meetings scheduled',
                  style: TextStyle(
                    color: DashboardColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...meetings.take(3).map((meeting) {
              final index = meetings.indexOf(meeting);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < meetings.length - 1 ? DashboardSizes.spacingSmall : 0,
                ),
                child: MeetingItem(
                  meeting: meeting,
                  onCheckIn: onCheckIn,
                  onAccept: onAcceptMeeting,
                  onReject: onRejectMeeting,
                  onClear: onClearMeeting,
                  onCancel: onCancelMeeting,
                  currentUserId: currentUserId,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}