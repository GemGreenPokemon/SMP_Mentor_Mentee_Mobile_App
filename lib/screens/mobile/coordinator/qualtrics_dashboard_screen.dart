import 'package:flutter/material.dart';

class QualtricsDataType {
  final String name;
  final IconData icon;
  final String description;

  QualtricsDataType({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class QualtricsDataItem {
  final String title;
  final String date;
  final String responseCount;
  final String type;
  final double completionRate;

  QualtricsDataItem({
    required this.title,
    required this.date,
    required this.responseCount,
    required this.type,
    required this.completionRate,
  });
}

class QualtricsFilterOption {
  final String name;
  bool isSelected;

  QualtricsFilterOption({
    required this.name,
    this.isSelected = false,
  });
}

class QualtricsExportFormat {
  final String name;
  final IconData icon;

  QualtricsExportFormat({
    required this.name,
    required this.icon,
  });
}

class QualtricsTimeRange {
  final String name;
  final String value;

  QualtricsTimeRange({
    required this.name,
    required this.value,
  });
}

class QualtricsDataCategory {
  final String name;
  final List<QualtricsDataItem> items;

  QualtricsDataCategory({
    required this.name,
    required this.items,
  });
}

class QualtricsDataInsight {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  QualtricsDataInsight({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class QualtricsDataDashboardScreen extends StatefulWidget {
  const QualtricsDataDashboardScreen({super.key});

  @override
  State<QualtricsDataDashboardScreen> createState() => _QualtricsDataDashboardScreenState();
}

class _QualtricsDataDashboardScreenState extends State<QualtricsDataDashboardScreen> {
  final List<QualtricsDataType> _dataTypes = [
    QualtricsDataType(
      name: 'Surveys',
      icon: Icons.poll,
      description: 'Program feedback and evaluation surveys',
    ),
    QualtricsDataType(
      name: 'Attendance',
      icon: Icons.how_to_reg,
      description: 'Event check-in and check-out records',
    ),
    QualtricsDataType(
      name: 'Feedback',
      icon: Icons.comment,
      description: 'Mentor-mentee session feedback',
    ),
    QualtricsDataType(
      name: 'Assessments',
      icon: Icons.assignment,
      description: 'Program outcome assessments',
    ),
  ];

  final List<QualtricsFilterOption> _filterOptions = [
    QualtricsFilterOption(name: 'All', isSelected: true),
    QualtricsFilterOption(name: 'Surveys'),
    QualtricsFilterOption(name: 'Attendance'),
    QualtricsFilterOption(name: 'Feedback'),
    QualtricsFilterOption(name: 'Assessments'),
  ];

  final List<QualtricsExportFormat> _exportFormats = [
    QualtricsExportFormat(name: 'CSV', icon: Icons.description),
    QualtricsExportFormat(name: 'Excel', icon: Icons.table_chart),
    QualtricsExportFormat(name: 'PDF', icon: Icons.picture_as_pdf),
  ];

  final List<QualtricsTimeRange> _timeRanges = [
    QualtricsTimeRange(name: 'Last 7 days', value: '7d'),
    QualtricsTimeRange(name: 'Last 30 days', value: '30d'),
    QualtricsTimeRange(name: 'Last 90 days', value: '90d'),
    QualtricsTimeRange(name: 'All time', value: 'all'),
  ];

  final List<QualtricsDataCategory> _dataCategories = [
    QualtricsDataCategory(
      name: 'Recent Surveys',
      items: [
        QualtricsDataItem(
          title: 'Mentor Program Satisfaction',
          date: 'May 15, 2023',
          responseCount: '42/50',
          type: 'Survey',
          completionRate: 0.84,
        ),
        QualtricsDataItem(
          title: 'Mentee Mid-Program Feedback',
          date: 'May 10, 2023',
          responseCount: '36/40',
          type: 'Survey',
          completionRate: 0.9,
        ),
        QualtricsDataItem(
          title: 'Workshop Effectiveness',
          date: 'May 5, 2023',
          responseCount: '28/35',
          type: 'Survey',
          completionRate: 0.8,
        ),
      ],
    ),
    QualtricsDataCategory(
      name: 'Recent Attendance Records',
      items: [
        QualtricsDataItem(
          title: 'Leadership Workshop',
          date: 'May 12, 2023',
          responseCount: '32/40',
          type: 'Attendance',
          completionRate: 0.8,
        ),
        QualtricsDataItem(
          title: 'Networking Event',
          date: 'May 8, 2023',
          responseCount: '45/50',
          type: 'Attendance',
          completionRate: 0.9,
        ),
        QualtricsDataItem(
          title: 'Career Development Seminar',
          date: 'May 3, 2023',
          responseCount: '38/45',
          type: 'Attendance',
          completionRate: 0.84,
        ),
      ],
    ),
    QualtricsDataCategory(
      name: 'Recent Feedback',
      items: [
        QualtricsDataItem(
          title: 'Mentor-Mentee Session Feedback',
          date: 'May 14, 2023',
          responseCount: '28/30',
          type: 'Feedback',
          completionRate: 0.93,
        ),
        QualtricsDataItem(
          title: 'Program Resources Feedback',
          date: 'May 7, 2023',
          responseCount: '25/40',
          type: 'Feedback',
          completionRate: 0.63,
        ),
      ],
    ),
  ];

  final List<QualtricsDataInsight> _insights = [
    QualtricsDataInsight(
      title: 'Average Attendance Rate',
      value: '85%',
      icon: Icons.people,
      color: Colors.blue,
    ),
    QualtricsDataInsight(
      title: 'Mentor Satisfaction',
      value: '4.7/5',
      icon: Icons.thumb_up,
      color: Colors.green,
    ),
    QualtricsDataInsight(
      title: 'Mentee Engagement',
      value: '92%',
      icon: Icons.trending_up,
      color: Colors.purple,
    ),
    QualtricsDataInsight(
      title: 'Survey Response Rate',
      value: '78%',
      icon: Icons.poll,
      color: Colors.orange,
    ),
  ];

  String _selectedTimeRange = '30d';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualtrics Data Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data...'),
                  duration: Duration(seconds: 1),
                ),
              );
              // TODO: Implement refresh functionality
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                // TODO: Implement settings
              } else if (value == 'help') {
                // TODO: Implement help
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('API Settings'),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Text('Help'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Type Cards
            const Text(
              'Data Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dataTypes.length,
                itemBuilder: (context, index) {
                  final dataType = _dataTypes[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        // TODO: Filter by data type
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing ${dataType.name} data'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              dataType.icon,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dataType.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: Text(
                                dataType.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Insights Section
            const Text(
              'Key Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _insights.length,
              itemBuilder: (context, index) {
                final insight = _insights[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: insight.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                insight.icon,
                                color: insight.color,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              insight.value,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: insight.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            insight.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Filter and Export Section
            Row(
              children: [
                const Text(
                  'Data Explorer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Time Range Dropdown
                DropdownButton<String>(
                  value: _selectedTimeRange,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTimeRange = newValue;
                      });
                    }
                  },
                  items: _timeRanges.map<DropdownMenuItem<String>>((range) {
                    return DropdownMenuItem<String>(
                      value: range.value,
                      child: Text(range.name),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                // Export Button
                PopupMenuButton<QualtricsExportFormat>(
                  icon: const Icon(Icons.download),
                  tooltip: 'Export Data',
                  onSelected: (QualtricsExportFormat format) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exporting data as ${format.name}...'),
                      ),
                    );
                    // TODO: Implement export functionality
                  },
                  itemBuilder: (context) => _exportFormats.map((format) {
                    return PopupMenuItem<QualtricsExportFormat>(
                      value: format,
                      child: Row(
                        children: [
                          Icon(format.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(format.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filterOptions.map((filter) {
                return FilterChip(
                  label: Text(filter.name),
                  selected: filter.isSelected,
                  onSelected: (selected) {
                    setState(() {
                      // If "All" is selected, deselect others
                      if (filter.name == 'All' && selected) {
                        for (var option in _filterOptions) {
                          option.isSelected = option.name == 'All';
                        }
                      } else {
                        // If another option is selected, deselect "All"
                        if (selected) {
                          for (var option in _filterOptions) {
                            if (option.name == 'All') {
                              option.isSelected = false;
                            }
                          }
                        }
                        filter.isSelected = selected;
                        
                        // If no options are selected, select "All"
                        bool anySelected = _filterOptions.any((option) => option.isSelected);
                        if (!anySelected) {
                          _filterOptions.firstWhere((option) => option.name == 'All').isSelected = true;
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Data Categories and Items
            ..._dataCategories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...category.items.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(item.type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.type,
                                    style: TextStyle(
                                      color: _getTypeColor(item.type),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.date,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.responseCount,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Completion Rate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: item.completionRate,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getProgressColor(item.completionRate),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${(item.completionRate * 100).toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getProgressColor(item.completionRate),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View Details'),
                                  onPressed: () {
                                    // TODO: Implement view details
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Viewing details for ${item.title}'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.download),
                                  label: const Text('Export'),
                                  onPressed: () {
                                    // TODO: Implement export
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Exporting ${item.title}...'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),

            // Create New Survey Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create New Survey'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // TODO: Implement create new survey
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Creating new survey...'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement quick action
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.add_chart),
                      title: const Text('Create New Survey'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement create new survey
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Creating new survey...'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Create Attendance Form'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement create attendance form
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Creating attendance form...'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('Create Feedback Form'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement create feedback form
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Creating feedback form...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Quick Actions',
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Survey':
        return Colors.blue;
      case 'Attendance':
        return Colors.green;
      case 'Feedback':
        return Colors.orange;
      case 'Assessment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double value) {
    if (value < 0.5) {
      return Colors.red;
    } else if (value < 0.7) {
      return Colors.orange;
    } else if (value < 0.9) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
} 