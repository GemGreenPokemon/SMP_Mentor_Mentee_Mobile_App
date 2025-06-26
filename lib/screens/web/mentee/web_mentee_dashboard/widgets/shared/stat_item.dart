import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? suffix;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? DashboardColors.accentBlue;
    
    return Container(
      padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
        border: Border.all(
          color: displayColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: displayColor,
                  size: DashboardSizes.iconSizeMedium,
                ),
              ),
            ),
            const SizedBox(width: DashboardSizes.spacingSmall + 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DashboardTextStyles.bodySmall.copyWith(
                    color: DashboardColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: DashboardTextStyles.h3.copyWith(
                        color: displayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        suffix!,
                        style: DashboardTextStyles.body.copyWith(
                          color: displayColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}