import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/screens/web/shared/web_register/web_register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TestRegisterAutofillApp());
}

class TestRegisterAutofillApp extends StatelessWidget {
  const TestRegisterAutofillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Register Autofill',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const WebRegisterScreen(),
    );
  }
}

// Test Information:
// The autofill button will only appear in debug mode
// It will populate the form with:
// - Name: Dasarathi Narayanan
// - Email: dnarayanan@ucmerced.edu
// - Password: Test123!
// - Student ID: 12345678