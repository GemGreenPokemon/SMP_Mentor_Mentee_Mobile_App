import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class MenteeListItem extends StatelessWidget {
  final String name;
  final String program;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onMessage;

  const MenteeListItem({
    super.key,
    required this.name,
    required this.program,
    required this.progress,
    required this.onTap,
    required this.onMessage,
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
        children: [
          Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.person),
              ),
              const SizedBox(width: DashboardSizes.spacingSmall + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: DashboardSizes.fontLarge,
                      ),
                    ),
                    Text(
                      program,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: DashboardSizes.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: onMessage,
                tooltip: DashboardStrings.message,
              ),
            ],
          ),
          const SizedBox(height: DashboardSizes.spacingSmall + 4),
          Row(
            children: [
              const Text(DashboardStrings.progress),
              const SizedBox(width: DashboardSizes.spacingSmall),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: DashboardColors.borderGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DashboardColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DashboardSizes.spacingSmall),
              Text(DashboardHelpers.formatPercentage(progress)),
            ],
          ),
        ],
      ),
    );
  }
}