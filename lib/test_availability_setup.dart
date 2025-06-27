import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Test script to verify Firestore structure and create test availability data
/// Run this with: flutter run -t lib/test_availability_setup.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Availability Setup',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _status = 'Initializing...';
  final List<String> _logs = [];
  
  @override
  void initState() {
    super.initState();
    _checkFirestoreStructure();
  }
  
  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
      print(message);
    });
  }
  
  Future<void> _checkFirestoreStructure() async {
    _log('Starting Firestore structure check...');
    
    // Check possible university paths
    final universityPaths = [
      'california_merced_uc_merced',  // Primary path
      'Campus01',  // Alternative if needed
      'ucmerced',  // Simplified format
    ];
    
    for (final path in universityPaths) {
      _log('\\nChecking university path: $path');
      
      try {
        // Check if university document exists
        final universityDoc = await _firestore.collection('universities').doc(path).get();
        if (universityDoc.exists) {
          _log('✅ Found university document: $path');
          _log('University data: ${universityDoc.data()}');
        } else {
          _log('❌ No university document at: universities/$path');
        }
        
        // Check data collection
        final dataPath = '$path/data';
        final dataDoc = await _firestore.collection(path).doc('data').get();
        if (dataDoc.exists) {
          _log('✅ Found data document at: $dataPath');
        } else {
          _log('❌ No data document at: $dataPath');
        }
        
        // Check availability collection
        final availabilityPath = '$path/data/availability';
        final availabilitySnapshot = await _firestore
            .collection(path)
            .doc('data')
            .collection('availability')
            .limit(5)
            .get();
        
        _log('Availability collection at $availabilityPath:');
        _log('  - Document count: ${availabilitySnapshot.docs.length}');
        
        for (final doc in availabilitySnapshot.docs) {
          final data = doc.data();
          _log('  - Doc ${doc.id}: mentor_id=${data['mentor_id']}, day=${data['day']}, slots=${data['slots']?.length ?? 0}');
        }
        
        // Check meetings collection
        final meetingsPath = '$path/data/meetings';
        final meetingsSnapshot = await _firestore
            .collection(path)
            .doc('data')
            .collection('meetings')
            .limit(5)
            .get();
        
        _log('Meetings collection at $meetingsPath:');
        _log('  - Document count: ${meetingsSnapshot.docs.length}');
        
      } catch (e) {
        _log('❌ Error checking $path: $e');
      }
    }
    
    setState(() {
      _status = 'Check complete. See logs below.';
    });
  }
  
  Future<void> _createTestAvailability() async {
    _log('\\nCreating test availability data...');
    
    // Use the correct university path
    const universityPath = 'california_merced_uc_merced';
    const mentorId = 'test_mentor_uid';
    const mentorDocId = 'Test_Mentor';
    final today = DateTime.now();
    final dayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      final availabilityCollection = _firestore
          .collection(universityPath)
          .doc('data')
          .collection('availability');
      
      final docId = '${mentorDocId}_$dayStr';
      
      final testData = {
        'id': docId,
        'mentor_id': mentorId,
        'day': dayStr,
        'slots': [
          {
            'slot_start': '9:00 AM',
            'slot_end': '10:00 AM',
            'is_booked': false,
            'mentee_id': null,
          },
          {
            'slot_start': '2:00 PM',
            'slot_end': '3:00 PM',
            'is_booked': false,
            'mentee_id': null,
          },
          {
            'slot_start': '4:00 PM',
            'slot_end': '5:00 PM',
            'is_booked': false,
            'mentee_id': null,
          },
        ],
        'synced': true,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await availabilityCollection.doc(docId).set(testData);
      _log('✅ Created test availability document: $docId');
      _log('Test data: $testData');
      
    } catch (e) {
      _log('❌ Error creating test data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Availability Setup'),
        backgroundColor: const Color(0xFF0F2D52),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _logs.clear();
                        });
                        _checkFirestoreStructure();
                      },
                      child: const Text('Re-check Structure'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _createTestAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Create Test Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.black;
                  if (log.contains('✅')) {
                    textColor = Colors.green;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}