import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: DashboardColors.statusRed,
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          const Text(
            DashboardStrings.errorLoadingData,
            style: TextStyle(fontSize: DashboardSizes.fontXLarge),
          ),
          const SizedBox(height: DashboardSizes.spacingSmall),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Text(DashboardStrings.retry),
          ),
        ],
      ),
    );
  }
}