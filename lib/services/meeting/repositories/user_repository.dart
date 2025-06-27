import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/meeting_constants.dart';
import '../managers/cache_manager.dart';

/// Repository for handling user-related operations needed by the meeting service
class UserRepository {
  final FirebaseFirestore _firestore;
  final String _universityPath;
  final MeetingCacheManager _cacheManager = MeetingCacheManager();
  
  UserRepository({
    required FirebaseFirestore firestore,
    required String universityPath,
  }) : _firestore = firestore,
       _universityPath = universityPath;
  
  /// Get the users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore
          .collection(_universityPath)
          .doc('data')
          .collection(MeetingConstants.usersCollection);
  
  /// Get user document ID from Firebase UID
  /// Uses cache to minimize Firestore queries
  Future<String?> getUserDocIdFromUid(String uid) async {
    // Check cache first
    final cachedDocId = _cacheManager.getCachedUserDocId(uid);
    if (cachedDocId != null) {
      return cachedDocId;
    }
    
    try {
      final userQuery = await _usersCollection
          .where('firebase_uid', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final docId = userQuery.docs.first.id;
        _cacheManager.cacheUserDocId(uid, docId);
        return docId;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user document ID: $e');
      }
      return null;
    }
  }
  
  /// Get user data from Firebase UID
  /// Returns user document data including the document ID
  Future<Map<String, dynamic>?> getUserDataFromUid(String uid) async {
    // Check cache first
    final cachedData = _cacheManager.getCachedUserData(uid);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      final userQuery = await _usersCollection
          .where('firebase_uid', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final doc = userQuery.docs.first;
        final userData = {
          'id': doc.id,
          'name': doc.data()['name'],
          ...doc.data(),
        };
        
        _cacheManager.cacheUserData(uid, userData);
        _cacheManager.cacheUserDocId(uid, doc.id);
        
        return userData;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      return null;
    }
  }
  
  /// Get multiple users data by UIDs or document IDs (batch operation)
  /// Useful for getting both mentor and mentee data at once
  /// Handles both Firebase UIDs and document IDs (like "Dasarathi_Narayanan")
  Future<Map<String, Map<String, dynamic>>> getUsersDataByUids(List<String> uids) async {
    print('🔍 getUsersDataByUids called with: $uids');
    
    final results = <String, Map<String, dynamic>>{};
    final uncachedUids = <String>[];
    
    // Check cache for each UID
    for (final uid in uids) {
      final cachedData = _cacheManager.getCachedUserData(uid);
      if (cachedData != null) {
        results[uid] = cachedData;
      } else {
        uncachedUids.add(uid);
      }
    }
    
    // If all found in cache, return early
    if (uncachedUids.isEmpty) {
      return results;
    }
    
    try {
      // First, try to get documents by their IDs directly
      final docIdResults = <String, Map<String, dynamic>>{};
      final remainingUids = <String>[];
      
      for (final uid in uncachedUids) {
        // Check if this looks like a document ID (contains underscore, no special chars)
        if (uid.contains('_') && !uid.contains('@')) {
          print('🔍 Trying to fetch document directly by ID: $uid');
          try {
            final doc = await _usersCollection.doc(uid).get();
            if (doc.exists) {
              final userData = {
                'id': doc.id,
                'name': doc.data()?['name'] ?? '',
                'firebase_uid': doc.data()?['firebase_uid'] ?? uid, // Use uid as fallback
                ...doc.data() ?? {},
              };
              
              docIdResults[uid] = userData;
              _cacheManager.cacheUserData(uid, userData);
              print('✅ Found user by document ID: ${userData['name']}');
            } else {
              remainingUids.add(uid);
            }
          } catch (e) {
            remainingUids.add(uid);
          }
        } else {
          remainingUids.add(uid);
        }
      }
      
      // Add document ID results
      results.addAll(docIdResults);
      
      // If there are remaining UIDs, query by firebase_uid
      if (remainingUids.isNotEmpty) {
        print('🔍 Querying for remaining UIDs by firebase_uid: $remainingUids');
        final userQuery = await _usersCollection
            .where('firebase_uid', whereIn: remainingUids)
            .get();
        
        for (final doc in userQuery.docs) {
          final uid = doc.data()['firebase_uid'] as String?;
          if (uid != null) {
            final userData = {
              'id': doc.id,
              'name': doc.data()['name'] ?? '',
              'firebase_uid': uid,
              ...doc.data(),
            };
            
            results[uid] = userData;
            _cacheManager.cacheUserData(uid, userData);
            _cacheManager.cacheUserDocId(uid, doc.id);
            print('✅ Found user by firebase_uid: ${userData['name']}');
          }
        }
      }
      
      print('🔍 getUsersDataByUids returning ${results.length} results');
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting users data: $e');
      }
      return results;
    }
  }
  
  /// Clear cache for a specific user
  void clearUserCache(String uid) {
    _cacheManager.clearUserCache(uid);
  }
  
  /// Clear all user caches
  void clearAllCaches() {
    _cacheManager.clearAllCaches();
  }
}