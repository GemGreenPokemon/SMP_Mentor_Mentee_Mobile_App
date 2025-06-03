import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/mentorship.dart';
import '../services/local_database_service.dart';
import '../utils/test_mode_manager.dart';

class LocalMentorSelectionScreen extends StatefulWidget {
  const LocalMentorSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LocalMentorSelectionScreen> createState() => _LocalMentorSelectionScreenState();
}

class _LocalMentorSelectionScreenState extends State<LocalMentorSelectionScreen> {
  final _localDb = LocalDatabaseService.instance;
  List<User> _mentors = [];
  Map<String, int> _menteeCount = {};
  Map<String, List<String>> _menteeNames = {};
  bool _isLoading = true;
  String? _selectedMentorId;

  @override
  void initState() {
    super.initState();
    _loadMentors();
    
    // Pre-select current test mentor if in test mode
    if (TestModeManager.isTestMode && TestModeManager.currentTestMentor != null) {
      _selectedMentorId = TestModeManager.currentTestMentor!.id;
    }
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all mentors
      final mentors = await _localDb.getUsersByType('mentor');
      
      // Get mentee counts and names for each mentor
      final menteeCount = <String, int>{};
      final menteeNames = <String, List<String>>{};
      
      for (final mentor in mentors) {
        final mentorships = await _localDb.getMentorshipsByMentor(mentor.id);
        menteeCount[mentor.id] = mentorships.length;
        
        // Get mentee names
        final names = <String>[];
        for (final mentorship in mentorships) {
          final mentee = await _localDb.getUser(mentorship.menteeId);
          if (mentee != null) {
            names.add(mentee.name);
          }
        }
        menteeNames[mentor.id] = names;
      }
      
      setState(() {
        _mentors = mentors;
        _menteeCount = menteeCount;
        _menteeNames = menteeNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading mentors: $e')),
        );
      }
    }
  }

  Future<void> _selectMentor(User mentor) async {
    setState(() => _selectedMentorId = mentor.id);
    
    // Get mentee for this mentor
    User? selectedMentee;
    final mentorships = await _localDb.getMentorshipsByMentor(mentor.id);
    
    if (mentorships.isNotEmpty) {
      // Get the first mentee
      final firstMentorship = mentorships.first;
      selectedMentee = await _localDb.getUser(firstMentorship.menteeId);
    }
    
    // Enable test mode with selected mentor and auto-selected mentee
    await TestModeManager.enableTestMode(mentor: mentor, mentee: selectedMentee);
    
    if (mounted) {
      String message = 'Test mode enabled as ${mentor.name}';
      if (selectedMentee != null) {
        message += '\nAuto-selected mentee: ${selectedMentee.name}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true); // Return true to indicate selection made
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Test Mentor'),
        actions: [
          if (_selectedMentorId != null)
            TextButton(
              onPressed: () async {
                await TestModeManager.disableTestMode();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test mode disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context, false);
                }
              },
              child: const Text(
                'Disable Test Mode',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mentors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No mentors found in local database',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Could navigate to mock data generator
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Generate Mock Data'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMentors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mentors.length,
                    itemBuilder: (context, index) {
                      final mentor = _mentors[index];
                      final count = _menteeCount[mentor.id] ?? 0;
                      final names = _menteeNames[mentor.id] ?? [];
                      final isSelected = mentor.id == _selectedMentorId;
                      
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectMentor(mentor),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      child: Text(
                                        mentor.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mentor.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            mentor.email,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.badge,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ID: ${mentor.studentId ?? mentor.id.substring(0, 8)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.group,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$count mentee${count != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (names.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mentees:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          names.join(', '),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Joined ${_formatDate(mentor.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'recently';
    }
  }
}