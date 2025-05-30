import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/test_mode_manager.dart';
import '../services/mentor_service.dart';
import '../models/meeting_note.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/mentorship.dart';
import '../services/local_database_service.dart';
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
  
  // Database data
  List<MeetingNote> _dbMeetingNotes = [];
  List<User> _mentees = [];
  List<Meeting> _meetings = [];
  bool _isLoading = false;
  
  String get mentorName => widget.mentorName ?? 'Sarah Martinez';

  @override
  void initState() {
    super.initState();
    _loadMeetingNotes();
  }

  /// Load meeting notes from database if in test mode
  Future<void> _loadMeetingNotes() async {
    if (!TestModeManager.isTestMode || TestModeManager.currentTestUser == null) {
      return; // Use mock data
    }

    setState(() => _isLoading = true);

    try {
      final localDb = LocalDatabaseService.instance;
      final currentUser = TestModeManager.currentTestUser!;
      
      if (widget.isMentor) {
        // Load mentor's mentees and their meeting notes
        final mentorships = await localDb.getMentorshipsByMentor(currentUser.id);
        final menteesList = <User>[];
        final allMeetingNotes = <MeetingNote>[];
        final allMeetings = <Meeting>[];
        
        for (final mentorship in mentorships) {
          final mentee = await localDb.getUser(mentorship.menteeId);
          if (mentee != null) {
            menteesList.add(mentee);
            
            // Get meetings for this mentorship
            final meetings = await localDb.getMeetingsByMentorship(mentorship.mentorId, mentorship.menteeId);
            allMeetings.addAll(meetings);
            
            // Get meeting notes for this mentorship
            final notes = await localDb.getMeetingNotesByMentorship(mentorship.mentorId, mentorship.menteeId);
            allMeetingNotes.addAll(notes);
          }
        }
        
        setState(() {
          _mentees = menteesList;
          _dbMeetingNotes = allMeetingNotes;
          _meetings = allMeetings;
        });
      } else {
        // Load mentee's meeting notes with their mentor
        final menteeships = await localDb.getMentorshipsByMentee(currentUser.id);
        final allMeetingNotes = <MeetingNote>[];
        final allMeetings = <Meeting>[];
        
        for (final mentorship in menteeships) {
          // Get meetings for this mentorship
          final meetings = await localDb.getMeetingsByMentorship(mentorship.mentorId, mentorship.menteeId);
          allMeetings.addAll(meetings);
          
          // Get meeting notes for this mentorship
          final notes = await localDb.getMeetingNotesByMentorship(mentorship.mentorId, mentorship.menteeId);
          allMeetingNotes.addAll(notes);
        }
        
        setState(() {
          _dbMeetingNotes = allMeetingNotes;
          _meetings = allMeetings;
        });
      }
    } catch (e) {
      debugPrint('Error loading meeting notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Get filtered meeting notes based on current filters
  List<MeetingNote> get _filteredMeetingNotes {
    if (!TestModeManager.isTestMode) {
      return []; // Return empty for mock mode display
    }

    List<MeetingNote> filtered = List.from(_dbMeetingNotes);
    
    // Filter by mentee if specific mentee selected
    if (selectedMentee != 'All Mentees' && widget.isMentor) {
      final selectedMenteeUser = _mentees.firstWhere((m) => m.name == selectedMentee, orElse: () => _mentees.first);
      filtered = filtered.where((note) {
        final meeting = _meetings.firstWhere((m) => m.id == note.meetingId, orElse: () => _meetings.first);
        return meeting.menteeId == selectedMenteeUser.id;
      }).toList();
    }
    
    // Filter by time period
    if (selectedMonth != 'All Time') {
      final now = DateTime.now();
      DateTime cutoffDate;
      
      switch (selectedMonth) {
        case 'This Month':
          cutoffDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last Month':
          cutoffDate = DateTime(now.year, now.month - 1, 1);
          break;
        case 'Last 3 Months':
          cutoffDate = DateTime(now.year, now.month - 3, 1);
          break;
        default:
          cutoffDate = DateTime(1970); // Very old date
      }
      
      filtered = filtered.where((note) {
        return note.createdAt != null && note.createdAt!.isAfter(cutoffDate);
      }).toList();
    }
    
    // Sort by creation date (most recent first)
    filtered.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    final shouldUseDatabase = TestModeManager.isTestMode && TestModeManager.currentTestUser != null;
    
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
          if (shouldUseDatabase)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMeetingNotes,
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
                      items: _buildMenteeDropdownItems(),
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
          
          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : shouldUseDatabase
                    ? _buildDatabaseMeetingNotes()
                    : _buildMockMeetingNotes(),
          ),
        ],
      ),
      floatingActionButton: widget.isMentor ? FloatingActionButton(
        onPressed: () {
          // TODO: Add new meeting note
          _showCreateNoteDialog();
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  /// Build dropdown items for mentee selection
  List<DropdownMenuItem<String>> _buildMenteeDropdownItems() {
    List<String> menteeNames = ['All Mentees'];
    
    if (TestModeManager.isTestMode) {
      menteeNames.addAll(_mentees.map((mentee) => mentee.name));
    } else {
      // Mock data
      menteeNames.addAll(['Alice Johnson', 'Bob Wilson']);
    }
    
    return menteeNames.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  /// Build meeting notes from database
  Widget _buildDatabaseMeetingNotes() {
    final filteredNotes = _filteredMeetingNotes;
    
    if (filteredNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No meeting notes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Meeting notes will appear here after meetings are completed',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        final meeting = _meetings.firstWhere((m) => m.id == note.meetingId, orElse: () => _meetings.first);
        return _buildDatabaseMeetingNoteCard(note, meeting);
      },
    );
  }

  /// Build mock meeting notes (fallback)
  Widget _buildMockMeetingNotes() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: widget.isMentor 
        ? [
            _buildMockMeetingNoteCard(
              'Weekly Check-in',
              'Feb 15, 2024',
              'Discussed progress on research project. Alice is making good progress but needs help with literature review.',
              'Alice Johnson',
              4,
              true,
            ),
            _buildMockMeetingNoteCard(
              'Career Planning Session',
              'Feb 10, 2024',
              'Explored internship opportunities and updated resume. Bob is interested in software engineering roles.',
              'Bob Wilson',
              5,
              false,
            ),
            _buildMockMeetingNoteCard(
              'Academic Support',
              'Feb 5, 2024',
              'Reviewed midterm preparation strategies. Alice is struggling with calculus concepts.',
              'Alice Johnson',
              3,
              true,
            ),
          ]
        : [
            _buildMockMeetingNoteCard(
              'Weekly Check-in',
              'Feb 15, 2024',
              'Discussed progress on research project and academic goals.',
              mentorName,
              4,
              true,
            ),
            _buildMockMeetingNoteCard(
              'Career Planning Session',
              'Feb 10, 2024',
              'Explored internship opportunities and updated resume.',
              mentorName,
              5,
              false,
            ),
          ],
    );
  }

  /// Build meeting note card from database data
  Widget _buildDatabaseMeetingNoteCard(MeetingNote note, Meeting meeting) {
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
                    meeting.topic ?? 'Meeting',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(note.createdAt ?? DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Author info
            Row(
              children: [
                Icon(
                  note.isMentor ? Icons.school : Icons.person,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  note.isMentor ? 'Mentor Notes' : 'Mentee Notes',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                if (note.isShared)
                  const Icon(Icons.share, size: 16, color: Colors.green),
                if (note.isAiGenerated)
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
              ],
            ),
            
            const Divider(height: 24),
            
            // Meeting notes content
            Text(
              'Notes:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(note.rawNote),
            
            if (note.organizedNote != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'AI-Organized Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.organizedNote!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showNoteDetailsDialog(note),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Full Details'),
                ),
                if (widget.isMentor && note.isMentor) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _shareMeetingNote(note);
                    },
                    icon: Icon(note.isShared ? Icons.share : Icons.share_outlined),
                    label: Text(note.isShared ? 'Shared' : 'Share'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build mock meeting note card (fallback)
  Widget _buildMockMeetingNoteCard(
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      SizedBox(height: 8),
                      Text(
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

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Share or unshare a meeting note
  Future<void> _shareMeetingNote(MeetingNote note) async {
    final mentorService = Provider.of<MentorService>(context, listen: false);
    final success = await mentorService.shareMeetingNote(note.id, !note.isShared);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(note.isShared ? 'Note unshared' : 'Note shared with mentee'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMeetingNotes(); // Refresh the notes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update note sharing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show dialog to create a new meeting note
  void _showCreateNoteDialog() {
    final TextEditingController noteController = TextEditingController();
    Meeting? selectedMeeting;
    bool isShared = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Meeting Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meeting selector
                  const Text(
                    'Select Meeting:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Meeting>(
                    value: selectedMeeting,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a meeting',
                    ),
                    items: _meetings
                        .where((m) => DateTime.tryParse(m.startTime)?.isBefore(DateTime.now()) ?? false)
                        .map((meeting) {
                      final date = DateTime.tryParse(meeting.startTime);
                      final mentee = _mentees.firstWhere(
                        (u) => u.id == meeting.menteeId,
                        orElse: () => User(id: '', name: 'Unknown', email: '', userType: 'mentee', createdAt: DateTime.now()),
                      );
                      return DropdownMenuItem(
                        value: meeting,
                        child: Text(
                          '${mentee.name} - ${date != null ? _formatDate(date) : 'Unknown date'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMeeting = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Note content
                  const Text(
                    'Meeting Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your meeting notes here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Share with mentee option (only for mentors)
                  if (widget.isMentor)
                    CheckboxListTile(
                      title: const Text('Share with mentee'),
                      subtitle: const Text('Allow mentee to see these notes'),
                      value: isShared,
                      onChanged: (value) {
                        setDialogState(() {
                          isShared = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedMeeting == null || noteController.text.trim().isEmpty
                    ? null
                    : () async {
                        // Create new meeting note
                        final note = MeetingNote(
                          id: LocalDatabaseService.instance.generateId(),
                          meetingId: selectedMeeting!.id,
                          authorId: TestModeManager.currentTestUser!.id,
                          isMentor: widget.isMentor,
                          isShared: isShared,
                          rawNote: noteController.text.trim(),
                          organizedNote: null, // AI organization disabled for now
                          isAiGenerated: false,
                          createdAt: DateTime.now(),
                        );
                        
                        try {
                          await LocalDatabaseService.instance.createMeetingNote(note);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Meeting note added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadMeetingNotes(); // Refresh the list
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Add Note'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show full details dialog for a meeting note
  void _showNoteDetailsDialog(MeetingNote note) {
    // Find the associated meeting
    final meeting = _meetings.firstWhere(
      (m) => m.id == note.meetingId,
      orElse: () => Meeting(
        id: '',
        mentorId: '',
        menteeId: '',
        startTime: DateTime.now().toIso8601String(),
        createdAt: DateTime.now(),
      ),
    );
    
    // Find the mentee name
    final mentee = _mentees.firstWhere(
      (u) => u.id == meeting.menteeId,
      orElse: () => User(id: '', name: 'Unknown', email: '', userType: 'mentee', createdAt: DateTime.now()),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notes, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Meeting Notes - ${mentee.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meeting info
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${_formatDate(DateTime.tryParse(meeting.startTime) ?? DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Text('Location: ${meeting.location ?? "TBD"}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.topic, size: 16),
                          const SizedBox(width: 8),
                          Text('Topic: ${meeting.topic ?? "General Meeting"}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Note content
              const Text(
                'Meeting Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.rawNote,
                  style: const TextStyle(height: 1.5),
                ),
              ),
              
              // AI organized notes (if available)
              if (note.organizedNote != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'AI Organized Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    border: Border.all(color: Colors.purple[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.organizedNote!,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.purple[900],
                    ),
                  ),
                ),
              ],
              
              // Metadata
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (note.isShared)
                    Chip(
                      label: const Text('Shared with mentee'),
                      backgroundColor: Colors.green[100],
                      avatar: const Icon(Icons.share, size: 16),
                    ),
                  Text(
                    'Created: ${_formatDate(note.createdAt ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (note.authorId == TestModeManager.currentTestUser?.id)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditNoteDialog(note);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  /// Show edit dialog for a meeting note
  void _showEditNoteDialog(MeetingNote note) {
    final TextEditingController noteController = TextEditingController(text: note.rawNote);
    bool isShared = note.isShared;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Meeting Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note content
                  const Text(
                    'Meeting Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your meeting notes here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Share with mentee option (only for mentors)
                  if (widget.isMentor && note.isMentor)
                    CheckboxListTile(
                      title: const Text('Share with mentee'),
                      subtitle: const Text('Allow mentee to see these notes'),
                      value: isShared,
                      onChanged: (value) {
                        setDialogState(() {
                          isShared = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: noteController.text.trim().isEmpty
                    ? null
                    : () async {
                        // Update meeting note
                        final updatedNote = note.copyWith(
                          rawNote: noteController.text.trim(),
                          isShared: isShared,
                          updatedAt: DateTime.now(),
                        );
                        
                        try {
                          await LocalDatabaseService.instance.updateMeetingNote(updatedNote);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Meeting note updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadMeetingNotes(); // Refresh the list
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}