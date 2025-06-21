import 'package:flutter/material.dart';
import '../../models/summary_card_data.dart';
import '../../utils/report_constants.dart';

class SummaryCard extends StatelessWidget {
  final SummaryCardData data;

  const SummaryCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(ReportConstants.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(data.icon, color: data.color, size: 28),
                if (data.showTrend)
                  Icon(
                    data.isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                    color: data.isPositiveTrend ? Colors.green : Colors.red,
                    size: 20,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: ReportConstants.largeValueTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              style: TextStyle(
                fontSize: ReportConstants.bodyTextSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: TextStyle(
                fontSize: ReportConstants.captionTextSize,
                color: data.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}