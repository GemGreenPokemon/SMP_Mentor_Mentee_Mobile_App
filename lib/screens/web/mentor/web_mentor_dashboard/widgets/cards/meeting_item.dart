import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class MeetingItem extends StatelessWidget {
  final String title;
  final String menteeName;
  final String time;
  final String location;
  final Color color;
  final VoidCallback onTap;

  const MeetingItem({
    super.key,
    required this.title,
    required this.menteeName,
    required this.time,
    required this.location,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: DashboardSizes.fontLarge,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingSmall + 4),
          _buildInfoRow(Icons.person, menteeName),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.access_time, time),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.location_on, location),
          const SizedBox(height: DashboardSizes.spacingSmall + 4),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 28),
                textStyle: const TextStyle(fontSize: DashboardSizes.fontSmall),
              ),
              child: const Text(DashboardStrings.checkIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: DashboardSizes.iconSmall - 2,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: DashboardSizes.fontMedium,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}