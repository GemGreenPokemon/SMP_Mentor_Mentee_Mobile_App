import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import 'models/report_type.dart';
import 'models/time_period.dart';
import 'models/summary_card_data.dart';
import 'models/activity_item.dart';
import 'models/attendance_record.dart';
import 'models/goal_progress.dart';
import 'models/meeting_note.dart';
import 'models/academic_performance.dart';
import 'utils/report_constants.dart';
import 'utils/report_helpers.dart';
import 'widgets/layout/report_app_bar.dart';
import 'widgets/filters/report_filters.dart';
import 'widgets/cards/summary_card.dart';
import 'widgets/content/overview_content.dart';
import 'widgets/content/attendance_content.dart';
import 'widgets/content/goal_progress_content.dart';
import 'widgets/content/meeting_notes_content.dart';
import 'widgets/content/academic_performance_content.dart';
import 'widgets/dialogs/export_dialog.dart';

class WebProgressReportsScreen extends StatefulWidget {
  const WebProgressReportsScreen({super.key});

  @override
  State<WebProgressReportsScreen> createState() => _WebProgressReportsScreenState();
}

class _WebProgressReportsScreenState extends State<WebProgressReportsScreen> {
  String selectedMentee = 'All Mentees';
  TimePeriod selectedPeriod = TimePeriod.currentSemester;
  ReportType selectedReportType = ReportType.overview;
  
  // Data
  late List<String> mentees;
  late List<SummaryCardData> summaryCards;
  late List<ActivityItem> recentActivities;
  late List<AttendanceRecord> attendanceRecords;
  late List<GoalProgress> goalProgressList;
  late List<MeetingNote> meetingNotes;
  late List<AcademicPerformance> academicPerformances;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // In production, this would load from Firebase
    mentees = ReportHelpers.getMockMentees();
    summaryCards = ReportHelpers.generateSummaryCards(selectedMentee);
    recentActivities = ReportHelpers.generateRecentActivities();
    attendanceRecords = ReportHelpers.generateAttendanceRecords();
    goalProgressList = ReportHelpers.generateGoalProgress();
    meetingNotes = ReportHelpers.generateMeetingNotes();
    academicPerformances = ReportHelpers.generateAcademicPerformance();
  }

  void _generateReport() {
    setState(() {
      // Refresh data based on filters
      summaryCards = ReportHelpers.generateSummaryCards(selectedMentee);
      // In production, this would fetch filtered data from Firebase
    });
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  void _handlePrint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ReportConstants.printingMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: ReportAppBar(
        onExport: _showExportDialog,
        onPrint: _handlePrint,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? ReportConstants.largePadding : ReportConstants.smallPadding),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: ReportConstants.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  ReportFilters(
                    selectedMentee: selectedMentee,
                    selectedPeriod: selectedPeriod,
                    selectedReportType: selectedReportType,
                    mentees: mentees,
                    onMenteeChanged: (value) => setState(() => selectedMentee = value),
                    onPeriodChanged: (value) => setState(() => selectedPeriod = value),
                    onReportTypeChanged: (value) => setState(() => selectedReportType = value),
                    onGenerateReport: _generateReport,
                    isDesktop: isDesktop,
                  ),
                  
                  const SizedBox(height: ReportConstants.mediumPadding),
                  
                  // Summary Cards (only for overview)
                  if (selectedReportType == ReportType.overview) ...[
                    _buildSummaryCards(isDesktop),
                    const SizedBox(height: ReportConstants.mediumPadding),
                  ],
                  
                  // Main Content
                  _buildMainContent(isDesktop, isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ReportConstants.getSummaryGridCrossAxisCount(isDesktop),
      crossAxisSpacing: ReportConstants.smallPadding,
      mainAxisSpacing: ReportConstants.smallPadding,
      childAspectRatio: isDesktop 
          ? ReportConstants.summaryCardAspectRatio 
          : ReportConstants.summaryCardAspectRatioMobile,
      children: summaryCards.map((card) => SummaryCard(data: card)).toList(),
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isTablet) {
    switch (selectedReportType) {
      case ReportType.overview:
        return OverviewContent(
          isDesktop: isDesktop,
          isTablet: isTablet,
          recentActivities: recentActivities,
        );
      case ReportType.attendance:
        return AttendanceContent(records: attendanceRecords);
      case ReportType.goalProgress:
        return GoalProgressContent(goalProgressList: goalProgressList);
      case ReportType.meetingNotes:
        return MeetingNotesContent(notes: meetingNotes);
      case ReportType.academicPerformance:
        return AcademicPerformanceContent(performances: academicPerformances);
    }
  }
}