import 'package:flutter/material.dart';
import '../../../models/meeting.dart';
import '../../../models/meeting_note.dart';
import '../../../services/local_database_service.dart';
import '../../../utils/test_mode_manager.dart';

class CheckInCheckOutScreen extends StatefulWidget {
  final String meetingTitle;
  final String mentorName;
  final String location;
  final String scheduledTime;
  final bool isMentor;
  final Meeting? meeting;  // Pass the actual meeting object if available

  const CheckInCheckOutScreen({
    super.key,
    required this.meetingTitle,
    required this.mentorName,
    required this.location,
    required this.scheduledTime,
    this.isMentor = false,
    this.meeting,
  });

  @override
  State<CheckInCheckOutScreen> createState() => _CheckInCheckOutScreenState();
}

class _CheckInCheckOutScreenState extends State<CheckInCheckOutScreen> {
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _mentorNotesController = TextEditingController();
  final TextEditingController _organizedNotesController = TextEditingController();
  bool _shareNotesWithMentor = true;
  bool _meetingVerified = false;
  bool _notesOrganized = false;
  bool _isOrganizing = false;
  int _meetingRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Simulate mentee already checked in for mentor view
    if (widget.isMentor) {
      _isCheckedIn = true;
      _checkInTime = DateTime.now().subtract(const Duration(minutes: 15));
      
      // Set initial raw mentor notes
      _mentorNotesController.text = '''discussed career goals w/ mentee
wants to do comp sci internship next summer
- showed good progress in courses
- need to work on interview prep
shared some links for internships
set targets for next sem
- python cert
- algo practice
connect w/ prof johnson re: research?
good interest in AI/ML''';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _mentorNotesController.dispose();
    _organizedNotesController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _checkIn() {
    setState(() {
      _isCheckedIn = true;
      _checkInTime = DateTime.now();
    });
    
    // In a real app, you would send this data to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully checked in!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _checkOut() async {
    // Set the check-out time
    print("Check-out button pressed");
    setState(() {
      _checkOutTime = DateTime.now();
    });
    
    // Save meeting notes to database if in test mode
    if (TestModeManager.isTestMode && widget.meeting != null && TestModeManager.currentTestUser != null) {
      try {
        // Update meeting status to completed
        final updatedMeeting = widget.meeting!.copyWith(
          status: 'completed',
        );
        await LocalDatabaseService.instance.updateMeeting(updatedMeeting);
        
        // Save meeting notes if any were written
        final notesText = widget.isMentor ? _mentorNotesController.text : _notesController.text;
        if (notesText.trim().isNotEmpty) {
          final note = MeetingNote(
            id: LocalDatabaseService.instance.generateId(),
            meetingId: widget.meeting!.id,
            authorId: TestModeManager.currentTestUser!.id,
            isMentor: widget.isMentor,
            isShared: widget.isMentor ? _shareNotesWithMentor : true,
            rawNote: notesText.trim(),
            organizedNote: _notesOrganized ? _organizedNotesController.text.trim() : null,
            isAiGenerated: false,
            createdAt: DateTime.now(),
          );
          
          await LocalDatabaseService.instance.createMeetingNote(note);
        }
      } catch (e) {
        debugPrint('Error saving meeting data: $e');
      }
    }
    
    // Show the rating dialog for mentees
    if (!widget.isMentor) {
      _showRatingDialog();
    } else {
      // For mentors, just mark as checked out without the rating dialog
      setState(() {
        _isCheckedOut = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have checked out successfully! Meeting notes saved.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _verifyMeeting() {
    setState(() {
      _meetingVerified = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting verified successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRatingDialog() {
    print("Showing rating dialog");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Meeting Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How would you rate this meeting?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _meetingRating ? Icons.star : Icons.star_border,
                            color: index < _meetingRating ? Colors.amber : Colors.grey,
                            size: 36,
                          ),
                          onPressed: () {
                            print("Star $index selected");
                            setDialogState(() {
                              _meetingRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Do you have any additional feedback?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts about the meeting...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print("Submit button pressed in dialog");
                    // Mark as checked out in the parent widget's state
                    setState(() {
                      _isCheckedOut = true;
                    });
                    
                    // Close the dialog
                    Navigator.pop(context);
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback submitted. You have checked out successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Mock function to simulate Gemini Pro API call
  void _organizeNotes() {
    setState(() {
      _isOrganizing = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 2), () {
      // This is a mock response - in real implementation, this would come from Gemini Pro API
      final organizedNotes = '''
Meeting Summary:
• Discussed career goals and internship opportunities in computer science
• Reviewed academic progress in current courses
• Set specific targets for the upcoming semester

Key Action Items:
• Student will apply to summer internship positions
• Complete Python certification course
• Practice algorithmic problem-solving

Resources Shared:
• Internship opportunity links
• Study materials for technical interviews

Next Steps:
• Follow up on internship applications
• Connect with Prof. Johnson about research opportunities
• Schedule interview preparation session

Additional Notes:
• Student showed strong interest in AI/ML specialization
• Notable progress in current coursework
• Consider research opportunities as additional experience
''';

      setState(() {
        _organizedNotesController.text = organizedNotes;
        _notesOrganized = true;
        _isOrganizing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes organized successfully using Gemini Pro!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _exportNotes() {
    // Create the text to share
    final String notesToShare = '''
MENTOR MEETING NOTES
${widget.meetingTitle}
Date: ${DateTime.now().toString().split(' ')[0]}

${_organizedNotesController.text}

Generated using Gemini Pro
''';

    // Show a custom share dialog instead of using share_plus
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.share, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Share via',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    context, 
                    Icons.email, 
                    'Email', 
                    Colors.red,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.message, 
                    'Messages', 
                    Colors.green,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.copy, 
                    'Copy', 
                    Colors.blue,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.drive_folder_upload, 
                    'Drive', 
                    Colors.yellow.shade800,
                    notesToShare,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    context, 
                    Icons.chat_bubble, 
                    'WhatsApp', 
                    Colors.green.shade700,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.cloud_upload, 
                    'Cloud', 
                    Colors.lightBlue,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.print, 
                    'Print', 
                    Colors.grey.shade700,
                    notesToShare,
                  ),
                  _buildShareOption(
                    context, 
                    Icons.more_horiz, 
                    'More', 
                    Colors.grey,
                    notesToShare,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Show success message after sharing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  Widget _buildShareOption(
    BuildContext context, 
    IconData icon, 
    String label, 
    Color color,
    String content,
  ) {
    return InkWell(
      onTap: () {
        // Close the bottom sheet
        Navigator.pop(context);
        
        // Show a mock "sharing" dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Share via $label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This is a mockup of sharing functionality.'),
                  const SizedBox(height: 12),
                  const Text('Content to share:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    height: 100,
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Share'),
                ),
              ],
            );
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 25,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Check-In/Out'),
        actions: [
          if (_isCheckedIn && !_isCheckedOut)
            TextButton.icon(
              onPressed: _checkOut,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Check Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.meetingTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text(widget.isMentor ? 'Mentee: John Doe' : 'Mentor: ${widget.mentorName}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Text('Location: ${widget.location}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text('Scheduled Time: ${widget.scheduledTime}'),
                      ],
                    ),
                    if (_isCheckedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.login, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              widget.isMentor ? 'Mentee Checked In: ${_formatTime(_checkInTime)}' : 'Checked In: ${_formatTime(_checkInTime)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    if (_isCheckedOut)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              widget.isMentor ? 'Mentee Checked Out: ${_formatTime(_checkOutTime)}' : 'Checked Out: ${_formatTime(_checkOutTime)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Mentor - Meeting Verification Section
            if (widget.isMentor && !_meetingVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Meeting Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please verify that this meeting took place with your mentee.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _verifyMeeting,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Verify Meeting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Mentor - Meeting verified badge
            if (widget.isMentor && _meetingVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Meeting Verified',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Check-in button (if not checked in yet) - Only for mentees
            if (!_isCheckedIn && !widget.isMentor)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Check In to Meeting'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            
            // Meeting in progress section (if checked in but not checked out)
            if (_isCheckedIn && !_isCheckedOut) ...[
              const SizedBox(height: 16),
              
              // Mentee Notes Section (visible to both mentee and mentor)
              if (!widget.isMentor) ...[
                // For mentee: input notes and share option
                const Text(
                  'Meeting Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Take notes during your meeting...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _shareNotesWithMentor,
                      onChanged: (value) {
                        setState(() {
                          _shareNotesWithMentor = value ?? true;
                        });
                      },
                    ),
                    const Text('Share these notes with my mentor'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Save notes logic would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notes saved!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Save Notes'),
                  ),
                ),
              ] else ...[
                // For mentor: view mentee's shared notes
                const Text(
                  'Mentee Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I really enjoyed our discussion about career options in computer science. The resources you shared were very helpful, and I plan to follow up on the internship opportunities we discussed.',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Shared at 14:30',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Mentor's own notes section
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: const Text(
                        'Your Notes (Mentor Only)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!_notesOrganized)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _isOrganizing ? null : _organizeNotes,
                          icon: _isOrganizing 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 20),
                          label: Text(_isOrganizing ? 'Organizing...' : 'Organize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mentorNotesController,
                  decoration: const InputDecoration(
                    hintText: 'Add your own notes about this meeting...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Save mentor notes logic would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mentor notes saved!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Notes'),
                      ),
                    ),
                  ],
                ),

                // Organized Notes Section (visible after organization)
                if (_notesOrganized || _isOrganizing) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Organized Notes (Gemini Pro)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      if (!_isOrganizing)
                        ElevatedButton.icon(
                          onPressed: _exportNotes,
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.05),
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isOrganizing
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Analyzing and organizing notes...',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextField(
                          controller: _organizedNotesController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          maxLines: null,
                          readOnly: true,
                          style: const TextStyle(height: 1.5),
                        ),
                  ),
                ],
              ],

              const SizedBox(height: 24),
              if (!widget.isMentor)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'When your meeting is complete, please click "Check Out" to provide feedback.',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isMentor)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'When your meeting is complete, please click "Check Out" in the top right.',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            
            // Meeting completed section (if checked out)
            if (_isCheckedOut) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Meeting Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isMentor) ...[
                      const SizedBox(height: 8),
                      Text('Your rating: ${_meetingRating}/5'),
                    ],
                    if (widget.isMentor && _meetingRating > 0) ...[
                      const SizedBox(height: 8),
                      const Text('Mentee\'s Feedback:'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Rating: '),
                          ...List.generate(5, (index) {
                            return Icon(
                              index < 4 ? Icons.star : Icons.star_border,
                              color: index < 4 ? Colors.amber : Colors.grey,
                              size: 18,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Great meeting! I really appreciated the resources you shared about internship opportunities.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Additional view for mentors - attendance confirmation
              if (widget.isMentor) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.event_available, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'Attendance Recorded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Meeting duration: 45 minutes'),
                      const SizedBox(height: 4),
                      const Text('This meeting will be recorded in the mentee\'s attendance record.'),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
} 