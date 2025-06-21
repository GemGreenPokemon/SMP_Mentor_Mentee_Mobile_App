import 'package:flutter/material.dart';
import '../../models/academic_performance.dart';
import '../../utils/report_constants.dart';

class AcademicPerformanceContent extends StatelessWidget {
  final List<AcademicPerformance> performances;

  const AcademicPerformanceContent({
    super.key,
    required this.performances,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(ReportConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic Performance',
              style: TextStyle(
                fontSize: ReportConstants.titleTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ReportConstants.mediumPadding),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mentee')),
                  DataColumn(label: Text('Current GPA')),
                  DataColumn(label: Text('Target GPA')),
                  DataColumn(label: Text('Credits Completed')),
                  DataColumn(label: Text('Status')),
                ],
                rows: performances.map((performance) => _buildDataRow(performance)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(AcademicPerformance performance) {
    return DataRow(
      cells: [
        DataCell(Text(performance.menteeName)),
        DataCell(Text(performance.currentGPA.toStringAsFixed(1))),
        DataCell(Text(performance.targetGPA.toStringAsFixed(1))),
        DataCell(Text('${performance.creditsCompleted}/${performance.totalCredits}')),
        DataCell(_buildStatusChip(performance.status)),
      ],
    );
  }

  Widget _buildStatusChip(AcademicStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportConstants.smallPadding / 1.5,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ReportConstants.chipBorderRadius),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w500,
          fontSize: ReportConstants.captionTextSize,
        ),
      ),
    );
  }
}