import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';
import 'lib/screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart';
import 'lib/screens/web/shared/web_login/web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TestMenteeDashboardApp());
}

class TestMenteeDashboardApp extends StatelessWidget {
  const TestMenteeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Mentee Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData) {
            // User is logged in, show dashboard
            return const WebMenteeDashboardScreen();
          }
          
          // User is not logged in, show login
          return const WebLoginScreen();
        },
      ),
    );
  }
}