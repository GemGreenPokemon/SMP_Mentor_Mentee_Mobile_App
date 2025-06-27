import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug widget to test availability queries
/// Add this to any screen to debug availability issues
class DebugAvailabilityWidget extends StatefulWidget {
  const DebugAvailabilityWidget({super.key});

  @override
  State<DebugAvailabilityWidget> createState() => _DebugAvailabilityWidgetState();
}

class _DebugAvailabilityWidgetState extends State<DebugAvailabilityWidget> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final List<String> _logs = [];
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }
  
  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
    print('DEBUG_WIDGET: $message');
  }
  
  Future<void> _runDebugTests() async {
    _logs.clear();
    _log('=== AVAILABILITY DEBUG START ===');
    
    // 1. Check current user
    final currentUser = _auth.currentUser;
    _log('Current user UID: ${currentUser?.uid ?? "NOT LOGGED IN"}');
    _log('Current user email: ${currentUser?.email ?? "N/A"}');
    
    // 2. Check collection path
    const universityPath = 'california_merced_uc_merced';
    final availabilityPath = '$universityPath/data/availability';
    _log('\\nAvailability collection path: $availabilityPath');
    
    // 3. Try to read all documents
    try {
      _log('\\nFetching ALL availability documents...');
      final allDocs = await _firestore
          .collection(universityPath)
          .doc('data')
          .collection('availability')
          .get();
      
      _log('Total documents found: ${allDocs.docs.length}');
      
      for (var doc in allDocs.docs) {
        final data = doc.data();
        _log('\\nDocument: ${doc.id}');
        _log('  mentor_id: ${data['mentor_id']}');
        _log('  day: ${data['day']}');
        _log('  slots: ${data['slots']?.length ?? 0}');
        
        // Check if mentor_id matches current user
        if (data['mentor_id'] == currentUser?.uid) {
          _log('  ✅ This document belongs to current user!');
        }
      }
    } catch (e) {
      _log('❌ Error fetching all docs: $e');
    }
    
    // 4. Try the specific query
    if (currentUser != null) {
      try {
        _log('\\nTrying query with mentor_id = ${currentUser.uid}...');
        final querySnapshot = await _firestore
            .collection(universityPath)
            .doc('data')
            .collection('availability')
            .where('mentor_id', isEqualTo: currentUser.uid)
            .get();
        
        _log('Query returned ${querySnapshot.docs.length} documents');
        
        if (querySnapshot.docs.isEmpty) {
          _log('❌ No documents match the current user\'s UID');
          _log('Make sure the availability data has mentor_id = ${currentUser.uid}');
        }
      } catch (e) {
        _log('❌ Query error: $e');
      }
    }
    
    // 5. Test the stream subscription
    if (currentUser != null) {
      _log('\\nTesting stream subscription...');
      final subscription = _firestore
          .collection(universityPath)
          .doc('data')
          .collection('availability')
          .where('mentor_id', isEqualTo: currentUser.uid)
          .snapshots()
          .listen(
            (snapshot) {
              _log('📊 Stream update: ${snapshot.docs.length} documents');
            },
            onError: (error) {
              _log('❌ Stream error: $error');
            },
          );
      
      // Cancel after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        subscription.cancel();
        _log('Stream subscription cancelled');
      });
    }
    
    _log('\\n=== DEBUG COMPLETE ===');
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Debug Availability',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    onPressed: _runDebugTests,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white70;
                  if (log.contains('✅')) textColor = Colors.green;
                  if (log.contains('❌')) textColor = Colors.red;
                  if (log.contains('===')) textColor = Colors.blue;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}