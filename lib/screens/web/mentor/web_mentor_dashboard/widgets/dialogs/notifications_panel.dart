import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/notification_item.dart';
import '../../utils/dashboard_constants.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const NotificationsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = [
      const NotificationItem(
        icon: Icons.assignment,
        title: 'New Progress Report Due',
        description: 'Submit your monthly progress report by Friday',
        time: '2 hours ago',
        color: DashboardColors.statusOrange,
        isUnread: true,
      ),
      const NotificationItem(
        icon: Icons.event,
        title: 'Upcoming Meeting',
        description: 'Meeting with Alice Johnson tomorrow at 2:00 PM',
        time: '5 hours ago',
        color: Colors.blue,
        isUnread: true,
      ),
      const NotificationItem(
        icon: Icons.check_circle,
        title: 'Goal Completed',
        description: 'Bob Wilson completed "Review study plan"',
        time: 'Yesterday',
        color: DashboardColors.statusGreen,
        isUnread: false,
      ),
      const NotificationItem(
        icon: Icons.message,
        title: 'New Message',
        description: 'Carlos Rodriguez sent you a message',
        time: '2 days ago',
        color: DashboardColors.statusPurple,
        isUnread: false,
      ),
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 80, right: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardSizes.spacingMedium),
        ),
        child: Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DashboardSizes.spacingMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: DashboardSizes.spacingSmall),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) => _buildNotificationItem(notifications[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DashboardSizes.spacingMedium + 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DashboardColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications,
            color: DashboardColors.primaryDark,
          ),
          const SizedBox(width: DashboardSizes.spacingSmall + 4),
          const Text(
            DashboardStrings.notifications,
            style: TextStyle(
              fontSize: DashboardSizes.fontXLarge,
              fontWeight: FontWeight.w600,
              color: DashboardColors.primaryDark,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text(DashboardStrings.markAllAsRead),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      color: notification.isUnread ? notification.color.withOpacity(0.05) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DashboardSizes.spacingMedium + 4,
              vertical: DashboardSizes.spacingSmall + 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: DashboardSizes.iconMedium,
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
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w500,
                                fontSize: DashboardSizes.fontMedium,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.time,
                        style: TextStyle(
                          fontSize: DashboardSizes.fontSmall,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}