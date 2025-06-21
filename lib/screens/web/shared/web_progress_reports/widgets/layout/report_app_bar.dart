import 'package:flutter/material.dart';
import '../../utils/report_constants.dart';

class ReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onExport;
  final VoidCallback onPrint;

  const ReportAppBar({
    super.key,
    required this.onExport,
    required this.onPrint,
  });

  @override
  Size get preferredSize => const Size.fromHeight(ReportConstants.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Progress Reports'),
      backgroundColor: ReportConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: onExport,
          tooltip: 'Export Report',
        ),
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: onPrint,
          tooltip: 'Print Report',
        ),
        const SizedBox(width: ReportConstants.tinyPadding),
      ],
    );
  }
}