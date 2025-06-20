import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';
import '../dialogs/mentee_details_dialog.dart';
import '../dialogs/remove_mentee_confirmation.dart';
import '../../../../../../../../../screens/web/shared/web_chat_screen.dart';
import '../../../../../../../../../screens/web/shared/web_schedule_meeting_screen.dart';
import '../../../../../../../../../services/mentor_service.dart';

class MenteeGridCard extends StatelessWidget {
  final Mentee mentee;
  final VoidCallback onRemove;

  const MenteeGridCard({
    super.key,
    required this.mentee,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    final totalGoals = mentee.goals.length;
    final completedGoals = mentee.goals.where((g) => g.completed).length;
    final goalProgress = totalGoals > 0 ? completedGoals / totalGoals : 0.0;

    return Card(
      elevation: DashboardSizes.cardElevation,
      child: InkWell(
        onTap: () => MenteeDetailsDialog.show(
          context,
          mentee,
          () => _navigateToChat(context),
        ),
        borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(DashboardSizes.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, mentorService),
              const SizedBox(height: DashboardSizes.spacingMedium),
              _buildAssignmentInfo(),
              const SizedBox(height: DashboardSizes.spacingSmall + 4),
              _buildLastMeeting(),
              const SizedBox(height: DashboardSizes.spacingMedium),
              _buildProgressIndicators(goalProgress, completedGoals, totalGoals),
              const Spacer(),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MentorService mentorService) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: DashboardColors.primaryDark,
          child: Text(
            DashboardHelpers.getInitials(mentee.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: DashboardSizes.fontMedium + 6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingSmall + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mentee.name,
                style: const TextStyle(
                  fontSize: DashboardSizes.fontLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                mentee.program,
                style: TextStyle(
                  fontSize: DashboardSizes.fontMedium,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value, mentorService),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message, size: DashboardSizes.iconMedium),
                  SizedBox(width: DashboardSizes.spacingSmall),
                  Text(DashboardStrings.sendMessage),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'schedule',
              child: Row(
                children: [
                  Icon(Icons.event, size: DashboardSizes.iconMedium),
                  SizedBox(width: DashboardSizes.spacingSmall),
                  Text(DashboardStrings.scheduleeMeeting),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: DashboardSizes.iconMedium, color: DashboardColors.statusRed),
                  SizedBox(width: DashboardSizes.spacingSmall),
                  Text(DashboardStrings.removeMentee, style: TextStyle(color: DashboardColors.statusRed)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DashboardSizes.spacingSmall, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.statusGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: DashboardSizes.iconSmall,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            mentee.assignedBy,
            style: TextStyle(
              fontSize: DashboardSizes.fontSmall,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastMeeting() {
    return Row(
      children: [
        Icon(Icons.access_time, size: DashboardSizes.iconSmall, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${DashboardStrings.lastMeeting}${mentee.lastMeeting}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicators(double goalProgress, int completedGoals, int totalGoals) {
    return Column(
      children: [
        _buildProgressRow(
          DashboardStrings.overallProgress,
          mentee.progress,
          DashboardColors.primaryDark,
          DashboardHelpers.formatPercentage(mentee.progress),
        ),
        const SizedBox(height: DashboardSizes.spacingSmall),
        _buildProgressRow(
          DashboardStrings.goalsCompleted,
          goalProgress,
          DashboardColors.statusGreen,
          '$completedGoals/$totalGoals',
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, double value, Color color, String text) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: DashboardSizes.fontSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: DashboardColors.borderGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: DashboardSizes.spacingSmall),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: DashboardSizes.fontSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.message, size: DashboardSizes.iconSmall),
          label: const Text(DashboardStrings.message),
          onPressed: () => _navigateToChat(context),
        ),
        TextButton.icon(
          icon: const Icon(Icons.info_outline, size: DashboardSizes.iconSmall),
          label: const Text(DashboardStrings.details),
          onPressed: () => MenteeDetailsDialog.show(
            context,
            mentee,
            () => _navigateToChat(context),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String value, MentorService mentorService) {
    switch (value) {
      case 'message':
        _navigateToChat(context);
        break;
      case 'schedule':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebScheduleMeetingScreen(isMentor: true),
          ),
        );
        break;
      case 'remove':
        RemoveMenteeConfirmation.show(context, mentee, onRemove);
        break;
    }
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebChatScreen(
          recipientName: mentee.name,
          recipientRole: mentee.program,
        ),
      ),
    );
  }
}