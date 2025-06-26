import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';

class DateDisplay extends StatelessWidget {
  const DateDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    final currentDate = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      padding: const EdgeInsets.all(AcknowledgmentSizes.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AcknowledgmentColors.primaryDark,
            size: AcknowledgmentSizes.iconSizeSmall,
          ),
          const SizedBox(width: AcknowledgmentSizes.spacingMedium),
          Text(
            AcknowledgmentStrings.dateLabel,
            style: TextStyle(
              fontSize: AcknowledgmentSizes.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: AcknowledgmentColors.primaryDark,
            ),
          ),
          Text(
            currentDate,
            style: TextStyle(
              fontSize: AcknowledgmentSizes.fontSizeMedium,
              color: AcknowledgmentColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}