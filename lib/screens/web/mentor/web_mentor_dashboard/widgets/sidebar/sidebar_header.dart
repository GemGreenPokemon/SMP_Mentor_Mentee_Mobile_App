import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DashboardSizes.spacingLarge,
        DashboardSizes.spacingXLarge,
        DashboardSizes.spacingLarge,
        DashboardSizes.spacingLarge,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Image.asset(
              'assets/images/My_SMP_Logo.png',
              height: 48,
              width: 48,
            ),
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          const Text(
            DashboardStrings.appTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DashboardStrings.appSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}