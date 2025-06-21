import 'package:flutter/material.dart';
import '../../models/report_type.dart';
import '../../models/time_period.dart';
import '../../utils/report_constants.dart';

class ReportFilters extends StatelessWidget {
  final String selectedMentee;
  final TimePeriod selectedPeriod;
  final ReportType selectedReportType;
  final List<String> mentees;
  final ValueChanged<String> onMenteeChanged;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final ValueChanged<ReportType> onReportTypeChanged;
  final VoidCallback onGenerateReport;
  final bool isDesktop;

  const ReportFilters({
    super.key,
    required this.selectedMentee,
    required this.selectedPeriod,
    required this.selectedReportType,
    required this.mentees,
    required this.onMenteeChanged,
    required this.onPeriodChanged,
    required this.onReportTypeChanged,
    required this.onGenerateReport,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(ReportConstants.standardPadding),
        child: Wrap(
          spacing: ReportConstants.smallPadding,
          runSpacing: ReportConstants.smallPadding,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildMenteeSelector(),
            _buildPeriodSelector(),
            _buildReportTypeSelector(),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenteeSelector() {
    return SizedBox(
      width: isDesktop ? ReportConstants.filterFieldWidth : double.infinity,
      child: DropdownButtonFormField<String>(
        value: selectedMentee,
        decoration: const InputDecoration(
          labelText: 'Select Mentee',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        items: mentees.map((mentee) {
          return DropdownMenuItem(
            value: mentee,
            child: Text(mentee),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) onMenteeChanged(value);
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      width: isDesktop ? ReportConstants.filterFieldWidth : double.infinity,
      child: DropdownButtonFormField<TimePeriod>(
        value: selectedPeriod,
        decoration: const InputDecoration(
          labelText: 'Time Period',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.date_range),
        ),
        items: TimePeriod.values.map((period) {
          return DropdownMenuItem(
            value: period,
            child: Text(period.displayName),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) onPeriodChanged(value);
        },
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return SizedBox(
      width: isDesktop ? ReportConstants.filterFieldWidth : double.infinity,
      child: DropdownButtonFormField<ReportType>(
        value: selectedReportType,
        decoration: const InputDecoration(
          labelText: 'Report Type',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.assessment),
        ),
        items: ReportType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.displayName),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) onReportTypeChanged(value);
        },
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: isDesktop ? ReportConstants.filterButtonWidth : double.infinity,
      height: ReportConstants.filterCardHeight,
      child: ElevatedButton.icon(
        onPressed: onGenerateReport,
        icon: const Icon(Icons.refresh),
        label: const Text('Generate Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ReportConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}