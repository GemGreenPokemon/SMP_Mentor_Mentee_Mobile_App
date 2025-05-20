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
    // TODO: Initialize Firestore database manually:
    // e.g., set default collections, seed data, clear old data.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firestore initialized (TODO)')),
    );
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
      appBar: AppBar(title: const Text('Firestore Manager')),
      body: Padding(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _initializeFirestore,
                child: const Text('Initialize Firestore DB'),
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
            const SizedBox(height: 16),
            const Text(
              'TODO: Integrate Firestore operations to fetch and display real metrics.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
