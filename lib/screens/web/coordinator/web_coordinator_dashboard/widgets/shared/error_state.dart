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
            color: Colors.red,
          ),
          const SizedBox(height: CoordinatorDashboardDimensions.paddingMedium),
          const Text(
            'Error loading dashboard data',
            style: TextStyle(fontSize: CoordinatorDashboardDimensions.fontSizeXLarge),
          ),
          const SizedBox(height: CoordinatorDashboardDimensions.paddingSmall),
          Text(
            error,
            style: TextStyle(color: CoordinatorDashboardColors.textSecondary),
          ),
          const SizedBox(height: CoordinatorDashboardDimensions.paddingMedium),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}