import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class MenteeDetailsDialog extends StatelessWidget {
  final Mentee mentee;
  final VoidCallback onMessage;

  const MenteeDetailsDialog({
    super.key,
    required this.mentee,
    required this.onMessage,
  });

  static void show(BuildContext context, Mentee mentee, VoidCallback onMessage) {
    showDialog(
      context: context,
      builder: (context) => MenteeDetailsDialog(
        mentee: mentee,
        onMessage: onMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(DashboardSizes.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: DashboardSizes.spacingLarge),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGoalsSection(),
                    const SizedBox(height: DashboardSizes.spacingLarge),
                    _buildUpcomingMeetingsSection(),
                    const SizedBox(height: DashboardSizes.spacingLarge),
                    _buildActionItemsSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DashboardSizes.spacingMedium),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: DashboardColors.primaryDark,
          child: Text(
            DashboardHelpers.getInitials(mentee.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: DashboardSizes.fontXXLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mentee.name,
                style: const TextStyle(
                  fontSize: DashboardSizes.fontMedium + 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                mentee.program,
                style: TextStyle(
                  fontSize: DashboardSizes.fontLarge,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          DashboardStrings.goals,
          style: TextStyle(
            fontSize: DashboardSizes.fontXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall + 4),
        if (mentee.goals.isNotEmpty)
          ...mentee.goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall),
                child: Row(
                  children: [
                    Icon(
                      goal.completed ? Icons.check_circle : Icons.circle_outlined,
                      color: goal.completed ? DashboardColors.statusGreen : Colors.grey,
                      size: DashboardSizes.iconMedium,
                    ),
                    const SizedBox(width: DashboardSizes.spacingSmall),
                    Expanded(
                      child: Text(
                        goal.goal,
                        style: TextStyle(
                          decoration: goal.completed ? TextDecoration.lineThrough : null,
                          color: goal.completed ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        else
          const Text(DashboardStrings.noGoalsSet),
      ],
    );
  }

  Widget _buildUpcomingMeetingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          DashboardStrings.upcomingMeetings,
          style: TextStyle(
            fontSize: DashboardSizes.fontXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall + 4),
        if (mentee.upcomingMeetings.isNotEmpty)
          ...mentee.upcomingMeetings.asMap().entries.map((entry) {
                final index = entry.key;
                final meeting = entry.value;
                final isFirst = index == 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall),
                  child: ListTile(
                    leading: Icon(
                      Icons.event,
                      color: isFirst ? DashboardColors.statusGreen : Colors.blue,
                    ),
                    title: Text(meeting.title),
                    subtitle: Text('${meeting.time} - ${meeting.location}'),
                    trailing: isFirst
                        ? const Chip(
                            label: Text(DashboardStrings.next, style: TextStyle(fontSize: DashboardSizes.fontSmall)),
                            backgroundColor: DashboardColors.statusGreen,
                            labelPadding: EdgeInsets.symmetric(horizontal: 4),
                          )
                        : null,
                  ),
                );
              })
        else
          const Text(DashboardStrings.noUpcomingMeetings),
      ],
    );
  }

  Widget _buildActionItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          DashboardStrings.actionItems,
          style: TextStyle(
            fontSize: DashboardSizes.fontXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall + 4),
        if (mentee.actionItems.isNotEmpty)
          ...mentee.actionItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.assignment, size: DashboardSizes.iconMedium, color: DashboardColors.statusOrange),
                    const SizedBox(width: DashboardSizes.spacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.item,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${DashboardStrings.due}${item.dueDate}',
                            style: TextStyle(
                              fontSize: DashboardSizes.fontSmall,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
        else
          const Text(DashboardStrings.noActionItems),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(DashboardStrings.close),
        ),
        const SizedBox(width: DashboardSizes.spacingSmall),
        ElevatedButton.icon(
          icon: const Icon(Icons.message),
          label: const Text(DashboardStrings.sendMessage),
          onPressed: () {
            Navigator.pop(context);
            onMessage();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DashboardColors.primaryDark,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}