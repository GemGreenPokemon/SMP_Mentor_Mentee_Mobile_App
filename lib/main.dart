import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import './screens/login_screen.dart';
import './screens/web_login_screen.dart';
import './screens/mentee_dashboard_screen.dart';
import './screens/web_mentee_dashboard_screen.dart';
import './screens/mentor_dashboard_screen.dart';
import './screens/web_mentor_dashboard_screen.dart';
import './screens/coordinator_dashboard_screen.dart';
import './screens/web_coordinator_dashboard_screen.dart';
import './screens/qualtrics_dashboard_screen.dart';
import './screens/developer_home_screen.dart';
import './screens/register_screen.dart';
import './screens/mentee_acknowledgment_screen.dart';
import './screens/settings_screen.dart';
import './screens/web_settings_screen.dart';
import './services/mentor_service.dart';
import './utils/responsive.dart';
import './utils/test_mode_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize TestModeManager first
  await TestModeManager.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final mentorService = MentorService();
            // Initialize with current test mode state
            mentorService.refresh();
            return mentorService;
          },
        ),
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
          seedColor: const Color(0xFF0F2D52),
          primary: const Color(0xFF0F2D52),
          secondary: const Color(0xFF2B4970),
          background: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F2D52),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Responsive.isWeb() 
            ? const WebLoginScreen() 
            : const LoginScreen(),
        '/dev': (context) => const DeveloperHomeScreen(),
        '/mentee': (context) => Responsive.isWeb()
            ? const WebMenteeDashboardScreen()
            : const MenteeDashboardScreen(),
        '/mentor': (context) => Responsive.isWeb()
            ? const WebMentorDashboardScreen()
            : const MentorDashboardScreen(),
        '/coordinator': (context) => Responsive.isWeb()
            ? const WebCoordinatorDashboardScreen()
            : const CoordinatorDashboardScreen(),
        '/qualtrics': (context) => const QualtricsDataDashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/mentee_acknowledgment': (context) => const MenteeAcknowledgmentScreen(),
        '/settings': (context) => Responsive.isWeb()
            ? const WebSettingsScreen()
            : const SettingsScreen(),
      },
    );
  }
}
