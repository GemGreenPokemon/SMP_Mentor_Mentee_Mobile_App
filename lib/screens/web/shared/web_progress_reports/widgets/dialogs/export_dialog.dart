import 'package:flutter/material.dart';
import '../../utils/report_constants.dart';

class ExportDialog extends StatelessWidget {
  const ExportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select export format:'),
          const SizedBox(height: ReportConstants.smallPadding),
          _buildExportOption(
            context,
            Icons.picture_as_pdf,
            'PDF Document',
            ReportConstants.exportingPdfMessage,
          ),
          _buildExportOption(
            context,
            Icons.table_chart,
            'Excel Spreadsheet',
            ReportConstants.exportingExcelMessage,
          ),
          _buildExportOption(
            context,
            Icons.description,
            'CSV File',
            ReportConstants.exportingCsvMessage,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    IconData icon,
    String title,
    String message,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }
}