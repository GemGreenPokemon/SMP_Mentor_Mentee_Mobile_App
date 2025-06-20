import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/meeting_item.dart';
import '../../models/dashboard_data.dart';

class MeetingsCarousel extends StatelessWidget {
  final List<Meeting> meetings;
  final VoidCallback onViewCalendar;
  final VoidCallback onCheckIn;

  const MeetingsCarousel({
    super.key,
    required this.meetings,
    required this.onViewCalendar,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DashboardSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(DashboardSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    DashboardStrings.upcomingMeetings,
                    style: TextStyle(
                      fontSize: DashboardSizes.fontXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onViewCalendar,
                  child: const Text(DashboardStrings.viewCalendar),
                ),
              ],
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            meetings.isEmpty
                ? Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: DashboardSizes.spacingSmall),
                        Text(
                          'No upcoming meetings',
                          style: TextStyle(
                            fontSize: DashboardSizes.fontLarge,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Schedule meetings with your mentees',
                          style: TextStyle(
                            fontSize: DashboardSizes.fontMedium,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < meetings.length; i++) ...[
                          if (i > 0) const SizedBox(width: DashboardSizes.spacingMedium),
                          SizedBox(
                            width: 280,
                            child: MeetingItem(
                              title: meetings[i].title,
                              menteeName: meetings[i].menteeName,
                              time: meetings[i].time,
                              location: meetings[i].location,
                              color: _getColorFromString(meetings[i].color),
                              onTap: onCheckIn,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return DashboardColors.statusGreen;
      case 'orange':
        return DashboardColors.statusOrange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}