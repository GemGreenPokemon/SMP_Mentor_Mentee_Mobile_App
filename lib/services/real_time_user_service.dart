import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class RealTimeUserService {
  static final RealTimeUserService _instance = RealTimeUserService._internal();
  factory RealTimeUserService() => _instance;
  RealTimeUserService._internal();

  FirebaseFirestore? _firestore;
  bool _isFirestoreInitialized = false;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _lastError;
  
  // Initialize Firestore with emulator settings
  void _initializeFirestore() {
    print('🔥 === FIRESTORE INITIALIZATION DEBUG ===');
    print('🔥 Is already initialized: $_isFirestoreInitialized');
    print('🔥 Current Firestore instance: $_firestore');
    
    if (_isFirestoreInitialized) {
      print('🔥 Firestore already initialized, skipping');
      print('🔥 Existing instance: $_firestore');
      return;
    }
    
    print('🔥 Creating new Firestore instance...');
    _firestore = FirebaseFirestore.instance;
    print('🔥 New Firestore instance created: $_firestore');
    
    // Use emulator when running locally
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    print('🔥 USE_EMULATOR environment variable: $useEmulator');
    print('🔥 kDebugMode: $kDebugMode');
    
    if (useEmulator == 'true' || kDebugMode) {
      try {
        print('🔥 Attempting to connect to Firestore emulator at 127.0.0.1:8080...');
        _firestore!.useFirestoreEmulator('127.0.0.1', 8080);
        print('🔥 ✅ Successfully connected to Firestore emulator');
      } catch (e) {
        print('🔥 ⚠️ Emulator connection failed or already connected: $e');
        print('🔥 Error type: ${e.runtimeType}');
      }
    } else {
      print('🔥 Using production Firestore (not emulator)');
    }
    
    _isFirestoreInitialized = true;
    print('🔥 Firestore initialization completed');
    print('🔥 Final instance: $_firestore');
    print('🔥 === END FIRESTORE INITIALIZATION ===');
  }
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  
  // Stream controllers
  final StreamController<List<User>> _usersController = StreamController<List<User>>.broadcast();
  final StreamController<ConnectionState> _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  // Public streams
  Stream<List<User>> get usersStream => _usersController.stream;
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  // Public getters
  ConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  
  // Current users list
  List<User> _currentUsers = [];
  List<User> get currentUsers => List.unmodifiable(_currentUsers);

  /// Start listening to real-time user updates for a university
  void startListening(String universityPath) {
    print('🔥 === REALTIMEUSERSERVICE DATABASE CONNECTION DEBUG ===');
    print('🔥 Starting to listen for universityPath: $universityPath');
    print('🔥 Full collection path will be: $universityPath/data/users');
    print('🔥 Firestore instance initialized: ${_isFirestoreInitialized}');
    print('🔥 Firestore instance: $_firestore');
    
    // Update connection state
    _updateConnectionState(ConnectionState.connecting);
    
    // Initialize Firestore if not already done
    _initializeFirestore();
    
    print('🔥 After initialization - Firestore instance: $_firestore');
    print('🔥 After initialization - Is initialized: $_isFirestoreInitialized');
    
    // Cancel any existing subscription
    stopListening();
    
    try {
      // Create the collection reference
      final usersCollection = _firestore!
          .collection(universityPath)
          .doc('data')
          .collection('users');
      
      print('🔥 Created collection reference successfully');
      print('🔥 Collection reference path: ${usersCollection.path}');
      print('🔥 Collection reference type: ${usersCollection.runtimeType}');
      
      // Start listening to real-time updates
      print('🔥 Starting snapshots listener...');
      _usersSubscription = usersCollection.snapshots().listen(
        (QuerySnapshot snapshot) {
          print('🔥 === SNAPSHOT RECEIVED ===');
          print('🔥 Snapshot received with ${snapshot.docs.length} documents');
          print('🔥 Snapshot metadata: ${snapshot.metadata}');
          print('🔥 Snapshot from cache: ${snapshot.metadata.isFromCache}');
          print('🔥 Snapshot has pending writes: ${snapshot.metadata.hasPendingWrites}');
          
          // Update connection state based on snapshot
          if (snapshot.docs.isNotEmpty || !snapshot.metadata.isFromCache) {
            _updateConnectionState(ConnectionState.connected);
          }
          
          if (snapshot.docs.isNotEmpty) {
            print('🔥 Raw documents in snapshot:');
            for (var i = 0; i < snapshot.docs.length; i++) {
              final doc = snapshot.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              print('🔥   Document $i: ID="${doc.id}"');
              print('🔥   Document $i: name="${data['name']}", email="${data['email']}"');
              print('🔥   Document $i: userType="${data['userType']}", firebase_uid="${data['firebase_uid']}"');
              print('🔥   Document $i: Full data keys: ${data.keys.toList()}');
            }
          } else {
            print('🔥 ❌ No documents found in snapshot!');
            print('🔥 This means the collection is empty or connection failed');
          }
          
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
              
              // Handle Firestore timestamps - convert all timestamp fields
              _convertTimestampField(data, 'created_at');
              _convertTimestampField(data, 'updated_at');
              _convertTimestampField(data, 'account_created_at');
              
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
          
          print('🔥 === FINAL USER LIST UPDATE ===');
          print('🔥 Successfully parsed and updated users list with ${users.length} users');
          print('🔥 Final user list summary:');
          for (var i = 0; i < users.length; i++) {
            final user = users[i];
            print('🔥   User $i: ${user.name} (${user.email}) - Type: ${user.userType}, Firebase UID: ${user.firebaseUid}');
          }
          print('🔥 === END REALTIMEUSERSERVICE DEBUG ===');
        },
        onError: (error) {
          print('🔥 RealTimeUserService: Error listening to users: $error');
          _updateConnectionState(ConnectionState.error, error.toString());
          _usersController.addError(error);
        },
      );
    } catch (e) {
      print('🔥 RealTimeUserService: Error starting listener: $e');
      _updateConnectionState(ConnectionState.error, e.toString());
      _usersController.addError(e);
    }
  }

  /// Stop listening to real-time updates
  void stopListening() {
    print('🔥 RealTimeUserService: Stopping listener');
    _usersSubscription?.cancel();
    _usersSubscription = null;
    _updateConnectionState(ConnectionState.disconnected);
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

  /// Helper method to convert timestamp fields to milliseconds
  void _convertTimestampField(Map<String, dynamic> data, String fieldName) {
    if (data[fieldName] == null) return;
    
    try {
      if (data[fieldName] is Timestamp) {
        // Convert Firestore Timestamp to milliseconds
        data[fieldName] = (data[fieldName] as Timestamp).millisecondsSinceEpoch;
        print('🔥 RealTimeUserService: Converted $fieldName Timestamp to milliseconds');
      } else if (data[fieldName] is Map) {
        // Handle Firestore timestamp format from cloud functions
        final timestamp = data[fieldName] as Map<String, dynamic>;
        if (timestamp['_seconds'] != null) {
          data[fieldName] = (timestamp['_seconds'] as int) * 1000;
          print('🔥 RealTimeUserService: Converted $fieldName Map timestamp to milliseconds');
        }
      } else if (data[fieldName] is int) {
        // Already in correct format (milliseconds)
        print('🔥 RealTimeUserService: $fieldName already in correct format (int)');
      } else {
        print('🔥 RealTimeUserService: Warning - $fieldName has unexpected type: ${data[fieldName].runtimeType}');
        // Convert to null if we can't handle the format
        data[fieldName] = null;
      }
    } catch (e) {
      print('🔥 RealTimeUserService: Error converting $fieldName timestamp: $e');
      // Set to null on error to prevent User.fromMap from failing
      data[fieldName] = null;
    }
  }

  /// Wait for database connection to be established
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 10)}) async {
    if (_connectionState == ConnectionState.connected) {
      return true;
    }
    
    final completer = Completer<bool>();
    late StreamSubscription subscription;
    
    subscription = _connectionStateController.stream.listen((state) {
      if (state == ConnectionState.connected) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        subscription.cancel();
      } else if (state == ConnectionState.error) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        subscription.cancel();
      }
    });
    
    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      subscription.cancel();
    });
    
    return completer.future;
  }

  /// Helper method to update connection state
  void _updateConnectionState(ConnectionState newState, [String? error]) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _lastError = error;
      _connectionStateController.add(newState);
      print('🔥 Connection state changed to: $newState${error != null ? ' (Error: $error)' : ''}');
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _usersController.close();
    _connectionStateController.close();
  }
}