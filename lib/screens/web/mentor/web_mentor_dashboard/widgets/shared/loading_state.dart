import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: DashboardColors.primaryDark,
      ),
    );
  }
}