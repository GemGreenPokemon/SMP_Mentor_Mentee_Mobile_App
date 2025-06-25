import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';
import '../shared/dashboard_card_container.dart';

class MentorInfoCard extends StatelessWidget {
  final MentorInfo mentorInfo;
  final VoidCallback onMessage;
  final VoidCallback onSchedule;

  const MentorInfoCard({
    super.key,
    required this.mentorInfo,
    required this.onMessage,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Mentor',
            style: DashboardTextStyles.h4,
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DashboardColors.accentBlue.withOpacity(0.8),
                      DashboardColors.accentPurple.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.accentBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mentorInfo.name.isNotEmpty ? mentorInfo.name[0].toUpperCase() : 'M',
                    style: DashboardTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorInfo.name,
                      style: DashboardTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mentorInfo.yearLevel}, ${mentorInfo.program}',
                      style: DashboardTextStyles.body,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assigned since ${mentorInfo.assignedDate}',
                      style: DashboardTextStyles.bodySmall.copyWith(
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardSizes.spacingMedium,
                      vertical: DashboardSizes.spacingSmall + 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingSmall + 4),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSchedule,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardSizes.spacingMedium,
                      vertical: DashboardSizes.spacingSmall + 4,
                    ),
                    side: BorderSide(
                      color: DashboardColors.borderMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}