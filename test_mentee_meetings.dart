import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';
import 'lib/services/dashboard_data_service.dart';
import 'lib/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TestMenteeMeetingsApp());
}

class TestMenteeMeetingsApp extends StatelessWidget {
  const TestMenteeMeetingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Mentee Meetings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const TestMenteeMeetingsScreen(),
    );
  }
}

class TestMenteeMeetingsScreen extends StatefulWidget {
  const TestMenteeMeetingsScreen({super.key});

  @override
  State<TestMenteeMeetingsScreen> createState() => _TestMenteeMeetingsScreenState();
}

class _TestMenteeMeetingsScreenState extends State<TestMenteeMeetingsScreen> {
  final DashboardDataService _dashboardService = DashboardDataService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final data = await _dashboardService.getMenteeDashboardData();
      
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mentee Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mentee Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mentee Profile',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Name: ${_dashboardData?['menteeProfile']?['name'] ?? 'Unknown'}'),
                              Text('Email: ${_dashboardData?['menteeProfile']?['email'] ?? 'Unknown'}'),
                              Text('Program: ${_dashboardData?['menteeProfile']?['program'] ?? 'Unknown'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mentor Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigned Mentor',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Name: ${_dashboardData?['mentorInfo']?['name'] ?? 'No mentor assigned'}'),
                              Text('Email: ${_dashboardData?['mentorInfo']?['email'] ?? 'N/A'}'),
                              Text('Program: ${_dashboardData?['mentorInfo']?['program'] ?? 'N/A'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Upcoming Meetings
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upcoming Meetings',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (_dashboardData?['upcomingMeetings']?.isEmpty ?? true)
                                const Text('No upcoming meetings scheduled')
                              else
                                ...(_dashboardData?['upcomingMeetings'] as List).map((meeting) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _getColorFromString(meeting['color']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getColorFromString(meeting['color']),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meeting['title'] ?? 'Meeting',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('Time: ${meeting['time'] ?? 'TBD'}'),
                                        Text('Location: ${meeting['location'] ?? 'TBD'}'),
                                        if (meeting['mentorName'] != null)
                                          Text('With: ${meeting['mentorName']}'),
                                        if (meeting['status'] != null)
                                          Text('Status: ${meeting['status']}'),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Color _getColorFromString(String? color) {
    switch (color) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}