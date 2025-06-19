import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';

class WebProgressReportsScreen extends StatefulWidget {
  const WebProgressReportsScreen({super.key});

  @override
  State<WebProgressReportsScreen> createState() => _WebProgressReportsScreenState();
}

class _WebProgressReportsScreenState extends State<WebProgressReportsScreen> {
  String selectedMentee = 'All Mentees';
  String selectedPeriod = 'Current Semester';
  String selectedReportType = 'Overview';

  // Mock data for mentees
  final List<String> mentees = [
    'All Mentees',
    'Alice Johnson',
    'Bob Wilson',
    'Carlos Rodriguez',
  ];

  // Mock data for periods
  final List<String> periods = [
    'Current Semester',
    'Last Semester',
    'Last 30 Days',
    'Last 90 Days',
    'All Time',
  ];

  // Mock data for report types
  final List<String> reportTypes = [
    'Overview',
    'Attendance',
    'Goal Progress',
    'Meeting Notes',
    'Academic Performance',
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing report for printing...')),
              );
            },
            tooltip: 'Print Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1400 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters Row
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          // Mentee Selector
                          SizedBox(
                            width: isDesktop ? 250 : double.infinity,
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
                                setState(() {
                                  selectedMentee = value!;
                                });
                              },
                            ),
                          ),
                          
                          // Period Selector
                          SizedBox(
                            width: isDesktop ? 250 : double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: selectedPeriod,
                              decoration: const InputDecoration(
                                labelText: 'Time Period',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.date_range),
                              ),
                              items: periods.map((period) {
                                return DropdownMenuItem(
                                  value: period,
                                  child: Text(period),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPeriod = value!;
                                });
                              },
                            ),
                          ),
                          
                          // Report Type Selector
                          SizedBox(
                            width: isDesktop ? 250 : double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: selectedReportType,
                              decoration: const InputDecoration(
                                labelText: 'Report Type',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.assessment),
                              ),
                              items: reportTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedReportType = value!;
                                });
                              },
                            ),
                          ),
                          
                          // Generate Report Button
                          SizedBox(
                            width: isDesktop ? 200 : double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  // Refresh data
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F2D52),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Summary Cards
                  if (selectedReportType == 'Overview')
                    _buildOverviewCards(isDesktop),
                  
                  const SizedBox(height: 24),
                  
                  // Main Content Area
                  if (selectedReportType == 'Overview')
                    _buildOverviewContent(isDesktop, isTablet),
                  if (selectedReportType == 'Attendance')
                    _buildAttendanceContent(isDesktop),
                  if (selectedReportType == 'Goal Progress')
                    _buildGoalProgressContent(isDesktop),
                  if (selectedReportType == 'Meeting Notes')
                    _buildMeetingNotesContent(isDesktop),
                  if (selectedReportType == 'Academic Performance')
                    _buildAcademicContent(isDesktop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.5 : 1.2,
      children: [
        _buildSummaryCard(
          'Total Meetings',
          '24',
          Icons.event,
          Colors.blue,
          '+12% from last period',
        ),
        _buildSummaryCard(
          'Attendance Rate',
          '92%',
          Icons.check_circle,
          Colors.green,
          'Above target',
        ),
        _buildSummaryCard(
          'Goals Completed',
          '18/25',
          Icons.flag,
          Colors.orange,
          '72% completion rate',
        ),
        _buildSummaryCard(
          'Active Mentees',
          selectedMentee == 'All Mentees' ? '3' : '1',
          Icons.people,
          Colors.purple,
          'All engaged',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewContent(bool isDesktop, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section
        Expanded(
          flex: isDesktop ? 3 : 1,
          child: Column(
            children: [
              // Meeting Frequency Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meeting Frequency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                    if (value.toInt() < months.length) {
                                      return Text(months[value.toInt()]);
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 3),
                                  const FlSpot(1, 4),
                                  const FlSpot(2, 3),
                                  const FlSpot(3, 5),
                                  const FlSpot(4, 4),
                                  const FlSpot(5, 6),
                                ],
                                isCurved: true,
                                color: const Color(0xFF0F2D52),
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Goal Progress Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Goal Progress by Mentee',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}%');
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    final names = ['Alice', 'Bob', 'Carlos'];
                                    if (value.toInt() < names.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          names[value.toInt()],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: 85,
                                    color: Colors.blue,
                                    width: 30,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: 72,
                                    color: Colors.green,
                                    width: 30,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: 90,
                                    color: Colors.orange,
                                    width: 30,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (isDesktop || isTablet) ...[
          const SizedBox(width: 24),
          
          // Recent Activities Section
          SizedBox(
            width: isDesktop ? 400 : 300,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActivityItem(
                      'Alice Johnson',
                      'Completed "Resume Building" goal',
                      '2 hours ago',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const Divider(height: 32),
                    _buildActivityItem(
                      'Bob Wilson',
                      'Submitted progress update',
                      '5 hours ago',
                      Icons.description,
                      Colors.blue,
                    ),
                    const Divider(height: 32),
                    _buildActivityItem(
                      'Carlos Rodriguez',
                      'Scheduled meeting for next week',
                      '1 day ago',
                      Icons.event,
                      Colors.orange,
                    ),
                    const Divider(height: 32),
                    _buildActivityItem(
                      'Alice Johnson',
                      'Updated career objectives',
                      '2 days ago',
                      Icons.edit,
                      Colors.purple,
                    ),
                    const Divider(height: 32),
                    _buildActivityItem(
                      'System',
                      'Monthly reports generated',
                      '3 days ago',
                      Icons.assessment,
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityItem(String name, String activity, String time, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceContent(bool isDesktop) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Add data table or calendar view for attendance
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Mentee')),
                DataColumn(label: Text('Meeting Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Duration')),
              ],
              rows: [
                _buildDataRow('May 15, 2024', 'Alice Johnson', 'Weekly Check-in', 'Present', '45 min'),
                _buildDataRow('May 14, 2024', 'Bob Wilson', 'Career Planning', 'Present', '60 min'),
                _buildDataRow('May 13, 2024', 'Carlos Rodriguez', 'Weekly Check-in', 'Absent', '-'),
                _buildDataRow('May 10, 2024', 'Alice Johnson', 'Goal Review', 'Present', '30 min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(String date, String mentee, String type, String status, String duration) {
    return DataRow(
      cells: [
        DataCell(Text(date)),
        DataCell(Text(mentee)),
        DataCell(Text(type)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Present' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Present' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(Text(duration)),
      ],
    );
  }

  Widget _buildGoalProgressContent(bool isDesktop) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Tracking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Add goal progress visualization
            ...['Alice Johnson', 'Bob Wilson', 'Carlos Rodriguez'].map((mentee) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentee,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGoalItem('Complete Resume', 100, Colors.green),
                  _buildGoalItem('Apply to 5 Internships', 60, Colors.orange),
                  _buildGoalItem('Improve GPA to 3.5', 75, Colors.blue),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String goal, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal),
              Text('${progress.toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingNotesContent(bool isDesktop) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Meeting Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Add meeting notes list
            _buildMeetingNoteCard(
              'Alice Johnson',
              'May 15, 2024',
              'Weekly Check-in',
              'Discussed progress on resume building. Alice has completed her first draft and will send it for review. Planning to apply to 3 internships this week.',
            ),
            const SizedBox(height: 16),
            _buildMeetingNoteCard(
              'Bob Wilson',
              'May 14, 2024',
              'Career Planning Session',
              'Explored career options in psychology. Bob is interested in clinical psychology and will research graduate programs. Set up informational interview with alumni.',
            ),
            const SizedBox(height: 16),
            _buildMeetingNoteCard(
              'Carlos Rodriguez',
              'May 10, 2024',
              'Academic Support',
              'Reviewed study strategies for upcoming finals. Carlos will implement the Pomodoro technique and create a study schedule. Follow up next week.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingNoteCard(String mentee, String date, String type, String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mentee,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            type,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicContent(bool isDesktop) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Add academic performance metrics
            DataTable(
              columns: const [
                DataColumn(label: Text('Mentee')),
                DataColumn(label: Text('Current GPA')),
                DataColumn(label: Text('Target GPA')),
                DataColumn(label: Text('Credits Completed')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Alice Johnson')),
                  const DataCell(Text('3.4')),
                  const DataCell(Text('3.5')),
                  const DataCell(Text('45/120')),
                  DataCell(_buildStatusChip('On Track', Colors.green)),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Bob Wilson')),
                  const DataCell(Text('3.7')),
                  const DataCell(Text('3.8')),
                  const DataCell(Text('60/120')),
                  DataCell(_buildStatusChip('Excellent', Colors.blue)),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Carlos Rodriguez')),
                  const DataCell(Text('2.8')),
                  const DataCell(Text('3.0')),
                  const DataCell(Text('30/120')),
                  DataCell(_buildStatusChip('Needs Support', Colors.orange)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting to PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting to Excel...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV File'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting to CSV...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}