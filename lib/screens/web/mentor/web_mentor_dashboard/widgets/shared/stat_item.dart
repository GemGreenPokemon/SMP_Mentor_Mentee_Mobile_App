import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DashboardSizes.spacingSmall + 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: DashboardSizes.iconXLarge,
          ),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall + 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: DashboardSizes.fontXXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: DashboardSizes.fontMedium,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}