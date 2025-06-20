import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          Text(
            message,
            style: TextStyle(
              fontSize: DashboardSizes.fontLarge,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}