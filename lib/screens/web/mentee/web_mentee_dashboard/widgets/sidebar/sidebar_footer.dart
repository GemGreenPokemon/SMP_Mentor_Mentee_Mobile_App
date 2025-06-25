import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardSizes.spacingMedium,
        vertical: DashboardSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DashboardColors.accentBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Help button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Show help/support
              },
              borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSizes.spacingMedium,
                  vertical: DashboardSizes.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: DashboardColors.textLight.withOpacity(0.7),
                      size: DashboardSizes.iconSizeSmall,
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall),
                    Text(
                      'Help & Support',
                      style: DashboardTextStyles.bodySmall.copyWith(
                        color: DashboardColors.textLight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Version info
          Text(
            'Version 1.0.0',
            style: DashboardTextStyles.caption.copyWith(
              color: DashboardColors.textLight.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}