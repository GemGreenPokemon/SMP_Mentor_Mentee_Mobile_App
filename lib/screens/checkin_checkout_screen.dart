import 'package:flutter/material.dart';

class CheckInCheckOutScreen extends StatefulWidget {
  final String meetingTitle;
  final String mentorName;
  final String location;
  final String scheduledTime;
  final bool isMentor;

  const CheckInCheckOutScreen({
    super.key,
    required this.meetingTitle,
    required this.mentorName,
    required this.location,
    required this.scheduledTime,
    this.isMentor = false,
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
  bool _shareNotesWithMentor = true;
  int _meetingRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
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

  void _checkOut() {
    // Set the check-out time
    print("Check-out button pressed");
    setState(() {
      _checkOutTime = DateTime.now();
    });
    
    // Show the rating dialog
    _showRatingDialog();
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
                        Text('Mentor: ${widget.mentorName}'),
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
                              'Checked In: ${_formatTime(_checkInTime)}',
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
                              'Checked Out: ${_formatTime(_checkOutTime)}',
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
            
            // Check-in button (if not checked in yet)
            if (!_isCheckedIn)
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'When your meeting is complete, please click "Check Out" to provide feedback.',
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
                    const SizedBox(height: 8),
                    Text('Your rating: ${_meetingRating}/5'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 