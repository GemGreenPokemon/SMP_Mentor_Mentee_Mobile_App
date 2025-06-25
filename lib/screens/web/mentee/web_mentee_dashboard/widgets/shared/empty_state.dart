import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DashboardSizes.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: DashboardColors.borderLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 48,
                  color: DashboardColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: DashboardSizes.spacingLarge),
            Text(
              title,
              style: DashboardTextStyles.h4.copyWith(
                color: DashboardColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DashboardSizes.spacingSmall),
              Text(
                subtitle!,
                style: DashboardTextStyles.body.copyWith(
                  color: DashboardColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: DashboardSizes.spacingLarge),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}