import 'package:flutter/material.dart';
import '../cards/mentee_list_item.dart';
import '../../models/coordinator_dashboard_data.dart';

class MenteesListSection extends StatelessWidget {
  final CoordinatorDashboardData dashboardData;
  
  const MenteesListSection({
    super.key,
    required this.dashboardData,
  });

  Widget _buildStatusIndicator(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mentees',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
                  onPressed: () {
                    // TODO: View all mentees
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Mentee List
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: _buildMenteeList(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenteeList(BuildContext context) {
    final mentees = dashboardData.mentees.take(3).toList();
    
    // Debug logging
    print('MenteesListSection - Total mentees: ${dashboardData.mentees.length}');
    print('MenteesListSection - Showing: ${mentees.length}');
    if (mentees.isNotEmpty) print('First mentee: ${mentees[0]}');
    
    if (mentees.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'No mentees available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ];
    }
    
    // Use real mentee data
    return mentees.map((mentee) {
      final status = mentee['status'] ?? 'Unassigned';
      final mentorName = mentee['mentorName'];
      Color statusColor;
      String displayStatus;
      
      if (status == 'Unassigned') {
        statusColor = Colors.green;
        displayStatus = 'Available';
      } else if (status == 'Assigned' && mentorName != null && mentorName != 'Unassigned') {
        statusColor = Colors.blue;
        displayStatus = 'Assigned to $mentorName';
      } else {
        statusColor = Colors.orange;
        displayStatus = status;
      }
      
      return MenteeListItem(
        name: mentee['name'] ?? 'Unknown Mentee',
        program: '${mentee['year_major'] ?? ''}, ${mentee['department'] ?? ''}',
        status: displayStatus,
        statusColor: statusColor,
        onManage: () {
          _showManageDialog(context, mentee);
        },
      );
    }).toList();
  }
  
  List<Widget> _buildFallbackMenteeList(BuildContext context) {
    return [
      MenteeListItem(
        name: 'Michael Brown',
        program: '1st Year, Computer Science',
        status: 'Available',
        statusColor: Colors.green,
        onManage: () {
          _showManageDialog(context, {
            'name': 'Michael Brown',
            'program': '1st Year, Computer Science',
          });
        },
      ),
      MenteeListItem(
        name: 'Lisa Chen',
        program: '2nd Year, Biology',
        status: 'Requested Mentor: Sarah Martinez (4th Year, Biology)',
        statusColor: Colors.orange,
        onApprove: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Approved mentor request for Lisa Chen'),
            ),
          );
        },
        onDeny: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Denied mentor request for Lisa Chen'),
            ),
          );
        },
      ),
      MenteeListItem(
        name: 'James Wilson',
        program: '1st Year, Psychology',
        status: 'Available',
        statusColor: Colors.green,
        onManage: () {
          _showManageDialog(context, {
            'name': 'James Wilson',
            'program': '1st Year, Psychology',
          });
        },
      ),
    ];
  }
  
  void _showManageDialog(BuildContext context, Map<String, dynamic> mentee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${mentee['name'] ?? 'Mentee'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose an option:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_off),
              title: const Text('Set as Inactive'),
              subtitle: const Text('Remove from available mentees list'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${mentee['name']} set as inactive'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // TODO: Revert status change
                      },
                    ),
                  ),
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