import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import '../features/mentee_registration/unit/services/auth_service_test.mocks.dart';

// Mock Firebase setup for tests
class FirebaseTestSetup {
  static late MockFirebaseAuth mockAuth;
  static late MockFirebaseFirestore mockFirestore;
  static late MockUser mockUser;
  
  static void initializeMocks() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    
    // Set up default behaviors
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
  }
  
  // Initialize Firebase with test configuration
  static Future<void> initializeFirebase() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // For unit tests, we typically don't need real Firebase
    // For integration tests, you might want to use Firebase emulator
  }
}