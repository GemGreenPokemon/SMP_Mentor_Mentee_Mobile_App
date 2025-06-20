import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../cards/meeting_item.dart';

class MeetingsCarousel extends StatelessWidget {
  final VoidCallback onViewCalendar;
  final VoidCallback onCheckIn;

  const MeetingsCarousel({
    super.key,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: MeetingItem(
                      title: 'Weekly Check-in',
                      menteeName: 'Alice Johnson',
                      time: 'Tomorrow at 2:00 PM',
                      location: 'KL 109',
                      color: Colors.blue,
                      onTap: onCheckIn,
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingMedium),
                  SizedBox(
                    width: 280,
                    child: MeetingItem(
                      title: 'Resume Review',
                      menteeName: 'Bob Wilson',
                      time: 'Friday at 4:30 PM',
                      location: 'Library Study Room 3',
                      color: DashboardColors.statusGreen,
                      onTap: onCheckIn,
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingMedium),
                  SizedBox(
                    width: 280,
                    child: MeetingItem(
                      title: 'Career Planning',
                      menteeName: 'Carlos Rodriguez',
                      time: 'Next Monday at 11:00 AM',
                      location: 'Virtual (Zoom)',
                      color: DashboardColors.statusOrange,
                      onTap: onCheckIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}