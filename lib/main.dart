import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smp_mentor_mentee_mobile_app/firebase_options.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/login_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_login_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/mentee/mentee_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentee/web_mentee_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/mentor/mentor_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/mentor/web_mentor_dashboard/web_mentor_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/coordinator/coordinator_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/coordinator/web_coordinator_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/coordinator/qualtrics_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/developer_home_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/register_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/mentee/mentee_acknowledgment_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/mobile/shared/settings_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/shared/web_settings/web_settings_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/services/mentor_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/mentee_service.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/test_mode_manager.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/developer_session.dart';
import 'package:smp_mentor_mentee_mobile_app/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Connect to emulators if USE_EMULATOR is set
    const useEmulator = String.fromEnvironment('USE_EMULATOR', defaultValue: 'false');
    if (useEmulator == 'true' || kDebugMode) {
      try {
        // Initialize Firestore emulator
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
        print('🔥 Connected to Firestore emulator at 127.0.0.1:8080');
        
        // Initialize Auth emulator
        FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
        print('🔐 Connected to Auth emulator at 127.0.0.1:9099');
      } catch (e) {
        print('⚠️ Emulator connection failed: $e');
      }
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  // Initialize TestModeManager with timeout for web
  try {
    await TestModeManager.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    print('TestModeManager initialization failed: $e');
    // Continue without test mode for now
  }
  
  // Initialize DeveloperSession with timeout for web
  try {
    await DeveloperSession.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    print('DeveloperSession initialization failed: $e');
    // Continue without developer session for now
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TestModeManager.instance,
        ),
        ChangeNotifierProvider(
          create: (_) {
            final mentorService = MentorService();
            // Initialize with current test mode state (non-blocking)
            mentorService.refresh().catchError((e) {
              print('MentorService refresh failed: $e');
            });
            return mentorService;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final menteeService = MenteeService();
            // Initialize with current test mode state (non-blocking)
            menteeService.refresh().catchError((e) {
              print('MenteeService refresh failed: $e');
            });
            return menteeService;
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
        '/': (context) => const AuthWrapper(),
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
