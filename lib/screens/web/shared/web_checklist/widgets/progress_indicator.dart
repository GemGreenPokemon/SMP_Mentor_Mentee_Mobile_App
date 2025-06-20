import 'package:flutter/material.dart';
import '../utils/checklist_helpers.dart';

class ChecklistProgressIndicator extends StatelessWidget {
  final double progress;
  final int completedItems;
  final int totalItems;
  final bool showPercentage;
  final bool showItemCount;
  final double height;

  const ChecklistProgressIndicator({
    super.key,
    required this.progress,
    required this.completedItems,
    required this.totalItems,
    this.showPercentage = true,
    this.showItemCount = true,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = ChecklistHelpers.getProgressColor(progress);
    final percentageText = ChecklistHelpers.getProgressPercentage(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showItemCount || showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showItemCount)
                Text(
                  '$completedItems of $totalItems completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              if (showPercentage)
                Text(
                  percentageText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.grey[700],
                  ),
                ),
            ],
          ),
        if (showItemCount || showPercentage) const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: progressColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}