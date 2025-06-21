import 'package:flutter/material.dart';
import '../../models/goal_progress.dart';
import '../../utils/report_constants.dart';

class GoalProgressContent extends StatelessWidget {
  final List<GoalProgress> goalProgressList;

  const GoalProgressContent({
    super.key,
    required this.goalProgressList,
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
              'Goal Tracking',
              style: TextStyle(
                fontSize: ReportConstants.titleTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ReportConstants.mediumPadding),
            ...goalProgressList.map((progress) => _buildMenteeGoals(progress)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenteeGoals(GoalProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress.menteeName,
          style: const TextStyle(
            fontSize: ReportConstants.bodyTextSize + 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ReportConstants.smallPadding / 1.5),
        ...progress.goals.map((goal) => _buildGoalItem(goal)).toList(),
        const SizedBox(height: ReportConstants.mediumPadding),
      ],
    );
  }

  Widget _buildGoalItem(Goal goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReportConstants.tinyPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.title),
              Text('${goal.progress.toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: goal.progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}