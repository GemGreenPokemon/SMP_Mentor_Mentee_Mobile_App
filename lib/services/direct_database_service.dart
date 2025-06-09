import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DirectDatabaseService {
  static final DirectDatabaseService _instance = DirectDatabaseService._internal();
  factory DirectDatabaseService() => _instance;
  DirectDatabaseService._internal();

  static DirectDatabaseService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize university database structure directly (bypasses Cloud Functions)
  /// ⚠️ WARNING: This is for development/testing purposes only
  /// This bypasses all authentication, authorization, and business logic validation
  Future<Map<String, dynamic>> initializeUniversityDirect({
    required String state,
    required String city,
    required String campus,
    required String universityName,
  }) async {
    try {
      print('Starting direct database initialization...');
      
      // Create university path
      final universityPath = '${state}_${city}_${campus}'.toLowerCase().replaceAll(' ', '_');
      
      // Check if university already exists
      final universityDoc = await _firestore.collection('universities').doc(universityPath).get();
      if (universityDoc.exists) {
        throw Exception('University already initialized');
      }

      // Create university document
      final universityData = {
        'id': universityPath,
        'name': universityName,
        'state': state,
        'city': city,
        'campus': campus,
        'path': universityPath,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'direct_init', // Since we're bypassing auth for testing
      };

      print('Creating university document at: universities/$universityPath');
      await _firestore.collection('universities').doc(universityPath).set(universityData);

      // Initialize collections structure
      final collectionsToCreate = [
        'users',
        'mentorships', 
        'meetings',
        'messages',
        'announcements',
        'progress_reports',
        'events',
        'resources',
        'checklists',
        'newsletters',
        'notifications'
      ];

      print('Creating collection structure...');
      
      // Create batch for efficiency
      final batch = _firestore.batch();

      // Create initial documents in each collection to establish structure
      for (final collectionName in collectionsToCreate) {
        final collectionRef = _firestore
            .collection(universityPath)
            .doc('data')
            .collection(collectionName);
            
        final metadataDoc = collectionRef.doc('_metadata');
        batch.set(metadataDoc, {
          'collection': collectionName,
          'created_at': FieldValue.serverTimestamp(),
          'created_by': 'direct_init',
          'version': 1,
          'description': 'Collection for $collectionName data'
        });
        
        print('  - Added $collectionName collection');
      }

      // Create default settings document
      final settingsRef = _firestore.collection(universityPath).doc('settings');
      batch.set(settingsRef, {
        'university_name': universityName,
        'academic_year': DateTime.now().year,
        'mentorship_program_active': true,
        'registration_open': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      print('Committing batch operations...');
      await batch.commit();

      print('University initialization completed successfully!');

      return {
        'success': true,
        'universityPath': universityPath,
        'message': 'University $universityName initialized successfully',
        'collections': collectionsToCreate,
        'method': 'direct_firestore'
      };

    } catch (e) {
      print('Error initializing university: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to initialize university: ${e.toString()}'
      };
    }
  }

  /// Test Firestore connection
  Future<bool> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      
      // Try to read from a test collection
      final testRef = _firestore.collection('_test').doc('connection');
      await testRef.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test successful'
      });
      
      final testDoc = await testRef.get();
      if (testDoc.exists) {
        print('✅ Firestore connection test successful');
        
        // Clean up test document
        await testRef.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  /// Get all universities (for testing)
  Future<List<Map<String, dynamic>>> getUniversities() async {
    try {
      print('Fetching universities...');
      
      final universitiesSnapshot = await _firestore.collection('universities').get();
      
      final universities = universitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('Found ${universities.length} universities');
      return universities;
      
    } catch (e) {
      print('Error fetching universities: $e');
      return [];
    }
  }

  /// Delete university (for testing cleanup)
  Future<bool> deleteUniversity(String universityPath) async {
    try {
      print('Deleting university: $universityPath');
      
      // Delete university document
      await _firestore.collection('universities').doc(universityPath).delete();
      
      // Note: This doesn't delete subcollections - that would require 
      // recursive deletion which is complex. For testing, this is sufficient.
      
      print('University deleted successfully');
      return true;
      
    } catch (e) {
      print('Error deleting university: $e');
      return false;
    }
  }
}