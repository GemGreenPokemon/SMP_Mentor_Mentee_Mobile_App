import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../utils/report_constants.dart';
import '../../utils/report_helpers.dart';

class AttendanceContent extends StatelessWidget {
  final List<AttendanceRecord> records;

  const AttendanceContent({
    super.key,
    required this.records,
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
              'Attendance Records',
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
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Mentee')),
                  DataColumn(label: Text('Meeting Type')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Duration')),
                ],
                rows: records.map((record) => _buildDataRow(record)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(AttendanceRecord record) {
    final statusColor = ReportHelpers.getAttendanceStatusColor(record.status);
    
    return DataRow(
      cells: [
        DataCell(Text(record.date)),
        DataCell(Text(record.mentee)),
        DataCell(Text(record.meetingType)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ReportConstants.smallPadding / 1.5,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ReportConstants.chipBorderRadius),
            ),
            child: Text(
              record.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(Text(record.duration)),
      ],
    );
  }
}