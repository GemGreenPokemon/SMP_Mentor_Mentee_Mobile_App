import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/mentee_dashboard_screen.dart';
import 'screens/mentor_dashboard_screen.dart';
import 'screens/coordinator_dashboard_screen.dart';
import 'screens/qualtrics_dashboard_screen.dart';
import 'services/mentor_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MentorService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMP Mentor-Mentee App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF64B5F6),
          background: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/mentee': (context) => const MenteeDashboardScreen(),
        '/mentor': (context) => const MentorDashboardScreen(),
        '/coordinator': (context) => const CoordinatorDashboardScreen(),
        '/qualtrics': (context) => const QualtricsDataDashboardScreen(),
      },
    );
  }
}
