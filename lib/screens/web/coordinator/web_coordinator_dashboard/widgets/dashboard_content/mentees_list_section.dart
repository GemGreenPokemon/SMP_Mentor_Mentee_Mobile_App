import 'package:flutter/material.dart';
import '../cards/mentee_list_item.dart';

class MenteesListSection extends StatelessWidget {
  const MenteesListSection({super.key});

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
              children: [
                MenteeListItem(
                  name: 'Michael Brown',
                  program: '1st Year, Computer Science',
                  status: 'Available',
                  statusColor: Colors.green,
                  onManage: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Manage Michael Brown'),
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
                                    content: const Text('Michael Brown set as inactive'),
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
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Manage James Wilson'),
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
                                    content: const Text('James Wilson set as inactive'),
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}