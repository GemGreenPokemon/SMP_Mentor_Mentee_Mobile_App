import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class RealTimeUserService {
  static final RealTimeUserService _instance = RealTimeUserService._internal();
  factory RealTimeUserService() => _instance;
  RealTimeUserService._internal();

  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
  
  // Initialize Firestore with emulator settings
  void _initializeFirestore() {
    if (_isFirestoreInitialized) {
      print('🔥 RealTimeUserService: Firestore already initialized, skipping');
      return;
    }
    
    _firestore = FirebaseFirestore.instance;
    
    // Use emulator when running locally
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    if (useEmulator == 'true' || kDebugMode) {
      try {
        _firestore!.useFirestoreEmulator('127.0.0.1', 8080);
        print('🔥 RealTimeUserService: Using Firestore emulator');
      } catch (e) {
        print('🔥 RealTimeUserService: Emulator already connected or error: $e');
      }
    } else {
      print('🔥 RealTimeUserService: Using production Firestore');
    }
    
    _isFirestoreInitialized = true;
  }
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  
  // Stream controller for real-time user updates
  final StreamController<List<User>> _usersController = StreamController<List<User>>.broadcast();
  
  // Public stream that screens can listen to
  Stream<List<User>> get usersStream => _usersController.stream;
  
  // Current users list
  List<User> _currentUsers = [];
  List<User> get currentUsers => List.unmodifiable(_currentUsers);

  /// Start listening to real-time user updates for a university
  void startListening(String universityPath) {
    print('🔥 RealTimeUserService: Starting to listen for universityPath: $universityPath');
    print('🔥 RealTimeUserService: Full path will be: $universityPath/data/users');
    
    // Initialize Firestore if not already done
    _initializeFirestore();
    
    // Cancel any existing subscription
    stopListening();
    
    try {
      // Create the collection reference
      final usersCollection = _firestore!
          .collection(universityPath)
          .doc('data')
          .collection('users');
      
      print('🔥 RealTimeUserService: Created collection reference: ${usersCollection.path}');
      
      // Start listening to real-time updates
      _usersSubscription = usersCollection.snapshots().listen(
        (QuerySnapshot snapshot) {
          print('🔥 RealTimeUserService: Received snapshot with ${snapshot.docs.length} documents');
          
          // Convert documents to User objects
          final users = snapshot.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add document ID
              
              // Skip metadata documents
              if (doc.id == '_metadata') {
                print('🔥 RealTimeUserService: Skipping metadata document');
                return null;
              }
              
              // Validate required fields for User
              if (data['name'] == null || data['email'] == null || data['userType'] == null) {
                print('🔥 RealTimeUserService: Skipping document ${doc.id} - missing required fields');
                return null;
              }
              
              // Handle mentee field - convert List to String if needed
              if (data['mentee'] is List) {
                final menteeList = data['mentee'] as List;
                data['mentee'] = menteeList.isNotEmpty ? menteeList.first.toString() : null;
                print('🔥 RealTimeUserService: Converted mentee list to string for ${doc.id}');
              }
              
              // Handle mentor field - convert List to String if needed  
              if (data['mentor'] is List) {
                final mentorList = data['mentor'] as List;
                data['mentor'] = mentorList.isNotEmpty ? mentorList.first.toString() : null;
                print('🔥 RealTimeUserService: Converted mentor list to string for ${doc.id}');
              }
              
              // Handle Firestore timestamps
              if (data['created_at'] is Timestamp) {
                data['created_at'] = (data['created_at'] as Timestamp).millisecondsSinceEpoch;
              } else if (data['created_at'] is Map) {
                // Handle Firestore timestamp format from cloud functions
                final timestamp = data['created_at'] as Map<String, dynamic>;
                if (timestamp['_seconds'] != null) {
                  data['created_at'] = timestamp['_seconds'] * 1000;
                }
              }
              
              if (data['updated_at'] is Timestamp) {
                data['updated_at'] = (data['updated_at'] as Timestamp).millisecondsSinceEpoch;
              }
              
              print('🔥 RealTimeUserService: Successfully parsed user ${doc.id}: ${data['name']}');
              return User.fromMap(data);
            } catch (e) {
              print('🔥 RealTimeUserService: Error parsing user document ${doc.id}: $e');
              print('🔥 RealTimeUserService: Document data: ${doc.data()}');
              return null;
            }
          }).whereType<User>().toList();
          
          // Update current users and notify listeners
          _currentUsers = users;
          _usersController.add(users);
          
          print('🔥 RealTimeUserService: Updated users list with ${users.length} users');
        },
        onError: (error) {
          print('🔥 RealTimeUserService: Error listening to users: $error');
          _usersController.addError(error);
        },
      );
    } catch (e) {
      print('🔥 RealTimeUserService: Error starting listener: $e');
      _usersController.addError(e);
    }
  }

  /// Stop listening to real-time updates
  void stopListening() {
    print('🔥 RealTimeUserService: Stopping listener');
    _usersSubscription?.cancel();
    _usersSubscription = null;
  }

  /// Update a user and the change will be reflected in real-time
  Future<bool> updateUser(String universityPath, String userId, Map<String, dynamic> updateData) async {
    try {
      print('🔥 RealTimeUserService: Updating user $userId in $universityPath');
      
      // Add timestamp
      updateData['updated_at'] = FieldValue.serverTimestamp();
      
      // Update in Firestore
      await _firestore!
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .doc(userId)
          .update(updateData);
      
      print('🔥 RealTimeUserService: User $userId updated successfully');
      return true;
    } catch (e) {
      print('🔥 RealTimeUserService: Error updating user $userId: $e');
      return false;
    }
  }

  /// Create a new user and the change will be reflected in real-time
  Future<String?> createUser(String universityPath, Map<String, dynamic> userData) async {
    try {
      print('🔥 RealTimeUserService: Creating new user in $universityPath');
      
      // Add timestamps
      userData['created_at'] = FieldValue.serverTimestamp();
      userData['updated_at'] = FieldValue.serverTimestamp();
      
      // Create in Firestore
      final docRef = await _firestore!
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .add(userData);
      
      print('🔥 RealTimeUserService: User created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔥 RealTimeUserService: Error creating user: $e');
      return null;
    }
  }

  /// Delete a user and the change will be reflected in real-time
  Future<bool> deleteUser(String universityPath, String userId) async {
    try {
      print('🔥 RealTimeUserService: Deleting user $userId from $universityPath');
      
      // Delete from Firestore
      await _firestore!
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .doc(userId)
          .delete();
      
      print('🔥 RealTimeUserService: User $userId deleted successfully');
      return true;
    } catch (e) {
      print('🔥 RealTimeUserService: Error deleting user $userId: $e');
      return false;
    }
  }

  /// Get user by ID from current cache
  User? getUserById(String userId) {
    try {
      return _currentUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Filter users by type
  List<User> getUsersByType(String userType) {
    return _currentUsers.where((user) => user.userType == userType).toList();
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _usersController.close();
  }
}