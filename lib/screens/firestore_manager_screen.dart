import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_test_screen.dart';
import 'dart:math';

class FirestoreManagerScreen extends StatefulWidget {
  const FirestoreManagerScreen({Key? key}) : super(key: key);

  @override
  State<FirestoreManagerScreen> createState() => _FirestoreManagerScreenState();
}

class _FirestoreManagerScreenState extends State<FirestoreManagerScreen> {
  int _readCount = 0;
  int _writeCount = 0;
  bool _dummyMenteeCreated = false;
  String? _dummyMenteeId;
  String? _dummyMenteeName;
  bool _isCreatingMentee = false;
  bool _showDatabasePreview = false;

  @override
  void initState() {
    super.initState();
    _checkDummyMenteeExists();
    // TODO: Fetch initial read/write counts from Firestore or metrics collection.
  }

  Future<void> _checkDummyMenteeExists() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isDummyUser', isEqualTo: true)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _dummyMenteeCreated = true;
          _dummyMenteeId = querySnapshot.docs.first.id;
          _dummyMenteeName = querySnapshot.docs.first.data()['name'] as String?;
        });
      }
    } catch (e) {
      print('Error checking for dummy mentee: $e');
    }
  }

  void _initializeFirestore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InitializeFirestoreDialog(
        onComplete: () {
          setState(() {
            _writeCount += 10; // Estimate for initial structure creation
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firestore initialized successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _toggleDatabasePreview() {
    setState(() {
      _showDatabasePreview = !_showDatabasePreview;
    });
  }

  Future<void> _createDummyMentee() async {
    if (_isCreatingMentee) return;
    
    setState(() {
      _isCreatingMentee = true;
    });
    
    try {
      // Generate a random ID suffix for the test mentee
      final random = Random();
      final idSuffix = random.nextInt(10000).toString().padLeft(4, '0');
      final menteeName = 'Test Mentee $idSuffix';
      
      // Create a document in the users collection
      final docRef = await FirebaseFirestore.instance.collection('users').add({
        'name': menteeName,
        'email': 'test.mentee.$idSuffix@example.com',
        'userType': 'mentee',
        'student_id': 'TEST$idSuffix',
        'department': 'Computer Science',
        'year_major': '3rd Year, Computer Science Major',
        'acknowledgment_signed': 'yes',
        'created_at': Timestamp.now(),
        'isDummyUser': true, // Flag to identify this as a test user
      });
      
      setState(() {
        _dummyMenteeCreated = true;
        _dummyMenteeId = docRef.id;
        _dummyMenteeName = menteeName;
        _writeCount++; // Increment the write count
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dummy mentee created: $menteeName')),
      );
    } catch (e) {
      print('Error creating dummy mentee: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating dummy mentee: $e')),
      );
    } finally {
      setState(() {
        _isCreatingMentee = false;
      });
    }
  }
  
  void _launchMessagingTest() {
    if (!_dummyMenteeCreated || _dummyMenteeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a dummy mentee first')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageTestScreen(
          recipientId: _dummyMenteeId!,
          recipientName: _dummyMenteeName ?? 'Dummy Mentee',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Manager'),
        actions: [
          IconButton(
            icon: Icon(_showDatabasePreview ? Icons.code_off : Icons.code),
            onPressed: _toggleDatabasePreview,
            tooltip: _showDatabasePreview ? 'Hide Database Preview' : 'Show Database Preview',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_download, size: 32, color: Colors.blue),
                            const SizedBox(height: 8),
                            const Text('Reads', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$_readCount', style: const TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload, size: 32, color: Colors.green),
                            const SizedBox(height: 8),
                            const Text('Writes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$_writeCount', style: const TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Database Preview Section
              if (_showDatabasePreview) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storage, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Database Structure Preview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildDatabasePreview(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initializeFirestore,
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('Initialize Firestore DB'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dummyMenteeCreated ? null : _createDummyMentee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dummyMenteeCreated ? Colors.grey[300] : Theme.of(context).primaryColor,
                    foregroundColor: _dummyMenteeCreated ? Colors.grey[600] : Colors.white,
                  ),
                  child: _isCreatingMentee
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_dummyMenteeCreated
                          ? 'Dummy Mentee Created: ${_dummyMenteeName ?? "Unknown"}'
                          : 'Add Dummy Mentee'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dummyMenteeCreated ? _launchMessagingTest : null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey[300]!;
                      }
                      return Colors.orange;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey[600]!;
                      }
                      return Colors.white;
                    }),
                  ),
                  child: const Text('Messaging Component Test'),
                ),
              ),
              const SizedBox(height: 16),
              if (_dummyMenteeCreated)
                Text(
                  'Dummy mentee ID: ${_dummyMenteeId ?? "Unknown"}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatabasePreview() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hierarchical Structure Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_tree, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Hierarchical Database Structure',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildHierarchyLevel('California', 0, isState: true),
                  _buildHierarchyLevel('Merced', 1, isCity: true),
                  _buildHierarchyLevel('UC_Merced', 2, isCampus: true),
                  Container(
                    margin: const EdgeInsets.only(left: 60, top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'All collections (users, meetings, etc.) exist under this path:\nCalifornia/Merced/UC_Merced/',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Users Collection Detail
            _buildCollectionPreview(
              'California/Merced/UC_Merced/users',
              'User profiles for mentors, mentees, and coordinators',
              _getSampleUserDocument(),
              hasSubcollections: true,
              subcollections: ['checklists', 'availability', 'messages', 'notes', 'ratings'],
              isExpanded: true, // Auto-expand users collection
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyLevel(String name, int level, {bool isState = false, bool isCity = false, bool isCampus = false}) {
    IconData icon;
    Color color;
    String label;
    
    if (isState) {
      icon = Icons.flag;
      color = Colors.purple;
      label = 'State';
    } else if (isCity) {
      icon = Icons.location_city;
      color = Colors.orange;
      label = 'City';
    } else {
      icon = Icons.school;
      color = Colors.green;
      label = 'Campus';
    }
    
    return Padding(
      padding: EdgeInsets.only(left: level * 20.0, top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPreview(
    String collectionName,
    String description,
    Map<String, dynamic> sampleDocument, {
    bool hasSubcollections = false,
    List<String>? subcollections,
    bool isExpanded = false,
  }) {
    return ExpansionTile(
      initiallyExpanded: isExpanded,
      title: Row(
        children: [
          Icon(Icons.folder, size: 20, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              collectionName,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, right: 8, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sample Document Structure:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sampleDocument.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: entry.value is String && entry.value.contains('Timestamp')
                              ? Colors.orange[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              if (hasSubcollections && subcollections != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Subcollections:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...subcollections.map((sub) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Icon(Icons.folder_open, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        sub,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSampleUserDocument() {
    return {
      'id': 'user_mentee_001',
      'name': 'Jane Smith',
      'email': 'jane.smith@ucmerced.edu',
      'userType': 'mentee',
      'student_id': 'JS12345',
      'mentor': 'JD54321', // mentor's student_id
      'department': 'Computer Science',
      'year_major': '3rd Year, Computer Science Major',
      'acknowledgment_signed': 'yes',
      'created_at': 'Timestamp',
    };
  }
}

// Initialize Firestore Dialog
class _InitializeFirestoreDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _InitializeFirestoreDialog({required this.onComplete});

  @override
  State<_InitializeFirestoreDialog> createState() => _InitializeFirestoreDialogState();
}

class _InitializeFirestoreDialogState extends State<_InitializeFirestoreDialog> {
  String _currentStep = '';
  double _progress = 0.0;
  bool _isComplete = false;
  final List<String> _completedSteps = [];

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final steps = [
      'Creating users collection...',
      'Creating meetings collection...',
      'Creating mentorships collection...',
      'Creating announcements collection...',
      'Creating events collection...',
      'Creating notifications collection...',
      'Creating action_items collection...',
      'Creating mentee_goals collection...',
      'Setting up security rules...',
      'Initialization complete!',
    ];

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        _currentStep = steps[i];
        _progress = (i + 1) / steps.length;
      });

      // Simulate async work
      await Future.delayed(const Duration(milliseconds: 500));

      if (i < steps.length - 1) {
        setState(() {
          _completedSteps.add(steps[i].replaceAll('...', ''));
        });
      }
    }

    setState(() {
      _isComplete = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isComplete ? Icons.check_circle : Icons.cloud_sync,
            color: _isComplete ? Colors.green : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(_isComplete ? 'Initialization Complete' : 'Initializing Firestore'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isComplete ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStep,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isComplete ? Colors.green : null,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _completedSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}