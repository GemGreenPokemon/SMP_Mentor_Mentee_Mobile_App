import 'package:flutter/material.dart';
import '../../models/meeting_note.dart';
import '../../utils/report_constants.dart';
import '../../utils/report_helpers.dart';

class MeetingNotesContent extends StatelessWidget {
  final List<MeetingNote> notes;

  const MeetingNotesContent({
    super.key,
    required this.notes,
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
              'Recent Meeting Notes',
              style: TextStyle(
                fontSize: ReportConstants.titleTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ReportConstants.mediumPadding),
            ...notes.map((note) => Column(
              children: [
                _buildMeetingNoteCard(note),
                if (note != notes.last)
                  const SizedBox(height: ReportConstants.smallPadding),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingNoteCard(MeetingNote note) {
    return Container(
      padding: const EdgeInsets.all(ReportConstants.smallPadding),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(ReportConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                note.menteeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ReportConstants.bodyTextSize + 2,
                ),
              ),
              Text(
                ReportHelpers.formatDate(note.date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ReportConstants.bodyTextSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.meetingType,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: ReportConstants.bodyTextSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ReportConstants.tinyPadding),
          Text(
            note.notes,
            style: const TextStyle(fontSize: ReportConstants.bodyTextSize),
          ),
          if (note.actionItems.isNotEmpty) ...[
            const SizedBox(height: ReportConstants.smallPadding),
            const Text(
              'Action Items:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: ReportConstants.bodyTextSize,
              ),
            ),
            const SizedBox(height: 4),
            ...note.actionItems.map((item) => Padding(
              padding: const EdgeInsets.only(left: ReportConstants.smallPadding, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: ReportConstants.bodyTextSize)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: ReportConstants.bodyTextSize),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }
}