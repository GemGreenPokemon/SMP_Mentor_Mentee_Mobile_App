import 'package:flutter/material.dart';
import 'checkin_checkout_screen.dart';

class MeetingNotesScreen extends StatefulWidget {
  final bool isMentor;
  final String? mentorName;
  
  const MeetingNotesScreen({
    super.key, 
    this.isMentor = true,
    this.mentorName,
  });

  @override
  State<MeetingNotesScreen> createState() => _MeetingNotesScreenState();
}

class _MeetingNotesScreenState extends State<MeetingNotesScreen> {
  String selectedMentee = 'All Mentees';
  String selectedMonth = 'All Time';
  
  String get mentorName => widget.mentorName ?? 'Sarah Martinez';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement advanced filtering
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.isMentor)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mentee',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedMentee,
                      items: [
                        'All Mentees',
                        'Alice Johnson',
                        'Bob Wilson',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMentee = value!;
                        });
                      },
                    ),
                  ),
                if (widget.isMentor)
                  const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedMonth,
                    items: [
                      'All Time',
                      'This Month',
                      'Last Month',
                      'Last 3 Months',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Meeting Notes List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: widget.isMentor 
                ? [
                    // Mentor view - show all mentees
                    _buildMeetingNoteCard(
                      'Weekly Check-in',
                      'Feb 15, 2024',
                      'Discussed progress on research project. Alice is making good progress but needs help with literature review.',
                      'Alice Johnson',
                      4, // Rating out of 5
                      true, // Has shared notes
                    ),
                    _buildMeetingNoteCard(
                      'Career Planning Session',
                      'Feb 10, 2024',
                      'Explored internship opportunities and updated resume. Bob is interested in software engineering roles.',
                      'Bob Wilson',
                      5,
                      false,
                    ),
                    _buildMeetingNoteCard(
                      'Academic Support',
                      'Feb 5, 2024',
                      'Reviewed midterm preparation strategies. Alice is struggling with calculus concepts.',
                      'Alice Johnson',
                      3,
                      true,
                    ),
                  ]
                : [
                    // Mentee view - show meetings with the mentee's mentor
                    _buildMeetingNoteCard(
                      'Weekly Check-in',
                      'Feb 15, 2024',
                      'Discussed progress on research project and academic goals.',
                      mentorName,
                      4, // Rating out of 5
                      true, // Has shared notes
                    ),
                    _buildMeetingNoteCard(
                      'Career Planning Session',
                      'Feb 10, 2024',
                      'Explored internship opportunities and updated resume.',
                      mentorName,
                      5,
                      false,
                    ),
                    _buildMeetingNoteCard(
                      'Academic Support',
                      'Feb 5, 2024',
                      'Reviewed midterm preparation strategies and study techniques.',
                      mentorName,
                      3,
                      true,
                    ),
                  ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isMentor ? FloatingActionButton(
        onPressed: () {
          // TODO: Add new meeting note
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildMeetingNoteCard(
    String title,
    String date,
    String content,
    String personName,
    int rating,
    bool hasSharedNotes,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  personName,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Meeting Rating: $rating/5',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (widget.isMentor) ...[
              const Text(
                'Mentor Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(content),
              if (hasSharedNotes) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.share, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Mentee Shared Notes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I found the discussion about research methods very helpful. I\'ll follow up on the resources you suggested and prepare a draft for our next meeting.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Your Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'I found the discussion about research methods very helpful. I\'ll follow up on the resources you suggested and prepare a draft for our next meeting.',
                style: TextStyle(height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // View full details
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Full Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 