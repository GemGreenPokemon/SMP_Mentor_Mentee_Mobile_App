import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class TopbarActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const TopbarActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 22,
              color: DashboardColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}