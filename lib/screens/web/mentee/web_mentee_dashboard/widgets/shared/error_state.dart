import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class ErrorState extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.error,
    this.onRetry,
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
                color: DashboardColors.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: DashboardColors.errorRed,
                ),
              ),
            ),
            const SizedBox(height: DashboardSizes.spacingLarge),
            Text(
              'Oops! Something went wrong',
              style: DashboardTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DashboardSizes.spacingSmall),
            Text(
              error ?? 'Failed to load dashboard data',
              style: DashboardTextStyles.body.copyWith(
                color: DashboardColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DashboardSizes.spacingLarge),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashboardSizes.spacingLarge,
                    vertical: DashboardSizes.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashboardSizes.buttonBorderRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}