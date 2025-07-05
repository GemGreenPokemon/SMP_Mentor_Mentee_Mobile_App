import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_parser_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_to_user_transformation_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/real_time_user_service.dart';
import 'package:smp_mentor_mentee_mobile_app/screens/web/coordinator/web_coordinator_dashboard/web_coordinator_dashboard_screen.dart';
import 'models/import_preview_data.dart';
import 'models/user_filter.dart';
import 'models/user_import_result.dart';
import 'utils/user_management_constants.dart';
import 'widgets/excel_upload_section.dart';
import 'widgets/import_preview_section.dart';
import 'widgets/user_list_section.dart';

class WebUserManagementScreen extends StatefulWidget {
  const WebUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<WebUserManagementScreen> createState() => _WebUserManagementScreenState();
}

class _WebUserManagementScreenState extends State<WebUserManagementScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final RealTimeUserService _userService = RealTimeUserService();
  final CloudFunctionService _cloudFunctionService = CloudFunctionService();
  final ExcelParserService _excelParser = ExcelParserService();
  final ExcelToUserTransformationService _transformationService = 
      ExcelToUserTransformationService();

  // State variables
  bool _isLoadingUsers = false;  // Separate loading state for users
  bool _isProcessingFile = false;  // Separate loading state for file processing
  bool _isImporting = false;  // Separate loading state for import operation
  String? _errorMessage;
  String? _fileName;  // Store filename like developer settings
  Map<String, dynamic>? _parseResults;  // Store raw parse results like developer settings
  ImportPreviewData? _importPreviewData;
  TransformationResult? _transformationResult;  // Store transformation result
  UserImportResult? _lastImportResult;
  List<User> _allUsers = [];
  UserFilter _currentFilter = UserFilter();
  StreamSubscription<List<User>>? _usersSubscription;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Delay initialization to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserService();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserService() async {
    setState(() {
      _isLoadingUsers = true;
      _errorMessage = null;
    });

    try {
      // Start listening to users
      final universityPath = _cloudFunctionService.getCurrentUniversityPath();
      _userService.startListening(universityPath);
      
      // Subscribe to user updates
      _usersSubscription = _userService.usersStream.listen((users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _isLoadingUsers = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load users: $error';
            _isLoadingUsers = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Real-time error: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
      
      // If we already have cached users, show them immediately
      final cachedUsers = _userService.currentUsers;
      if (cachedUsers.isNotEmpty && mounted) {
        setState(() {
          _allUsers = cachedUsers;
          _isLoadingUsers = false;
        });
      }
      
      // Set a timeout to clear loading state if no data comes through
      Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoadingUsers && _allUsers.isEmpty) {
          setState(() {
            _isLoadingUsers = false;
            _errorMessage = 'Timeout loading users. Please check your permissions.';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize user service: $e';
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    // Users are automatically loaded through the stream subscription
    // This method can be used for manual refresh if needed
    setState(() {
      _allUsers = _userService.currentUsers;
    });
  }

  Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isProcessingFile = true;
          _errorMessage = null;
          // Store filename like developer settings does
          _fileName = result.files.single.name;
        });

        // Parse Excel file
        await _excelParser.parseExcelFile(result.files.single.bytes!);
        
        // Parse the sheets - MUST await these async operations
        await _excelParser.parseMenteeAssignments();
        await _excelParser.parseMenteeInfo();

        // Get parse results statistics (like developer settings)
        var acknowledgmentStatus = _excelParser.getAcknowledgmentStatus();
        var topicStats = _excelParser.getTopicStatistics();
        var unassignedMentees = _excelParser.getUnassignedMentees();
        var allMentors = _excelParser.getAllMentors();
        var allMentees = _excelParser.getAllMentees();

        // Store parse results
        _parseResults = {
          'totalMentees': allMentees.length,
          'totalMentors': allMentors.length,
          'unassigned': unassignedMentees.length,
          'acknowledgmentStatus': acknowledgmentStatus,
          'topTopics': topicStats,
        };
        
        // Transform to users
        final transformationResult = _transformationService.transformToUsers(
          _excelParser.getAllAssignments(),
          _excelParser.getAllMenteeInfo(),
          importBatchId: 'excel_import_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Get all mentee info for additional data
        final menteeInfoMap = <String, MenteeInfo>{};
        for (var info in _excelParser.getAllMenteeInfo()) {
          menteeInfoMap[info.name] = info;
        }

        // Convert users to User objects with all available data
        final usersToImport = transformationResult.users.map((userData) {
          final name = userData['name'] ?? '';
          final menteeInfo = menteeInfoMap[name];
          
          // Generate a document ID based on the name (same as Firestore would do)
          final docId = name.replaceAll(' ', '_');
          
          return User(
            id: docId, // Use generated document ID
            name: name,
            email: userData['email'] ?? '',
            userType: userData['userType'] ?? 'mentee',
            createdAt: DateTime.now(),
            firebaseUid: null, // No Firebase UID yet - will be set after account creation
            studentId: userData['student_id'],
            mentor: userData['mentor'], // For mentees: their mentor's name
            mentee: userData['mentee'] is String ? userData['mentee'] : null, // For legacy single mentee
            mentees: userData['mentee'] is List ? List<String>.from(userData['mentee']) : null, // For mentors: list of mentee names
            acknowledgmentSigned: userData['acknowledgment_signed'] ?? 'not_applicable',
            department: userData['department'],
            yearMajor: userData['year_major'],
            careerAspiration: menteeInfo?.careerAspiration, // Get from menteeInfo
            topics: menteeInfo?.topics, // Get from menteeInfo
            importSource: userData['import_source'] ?? 'excel',
            importBatchId: userData['import_batch_id'] ?? 
              'excel_import_${DateTime.now().millisecondsSinceEpoch}',
          );
        }).toList();

        // Create preview data
        final preview = ImportPreviewData(
          usersToImport: usersToImport,
          menteeAssignments: _excelParser.getAllAssignments(),
          errors: transformationResult.errors.asMap().map((index, error) => 
            MapEntry(error.type, error.message)),
          warnings: transformationResult.warnings.asMap().map((index, warning) => 
            MapEntry(warning.type, warning.message)),
          totalUsers: transformationResult.users.length,
          mentorsCount: transformationResult.mentorMap.length,
          menteesCount: transformationResult.menteeMap.length,
          existingUsersCount: 0, // Would need to check against existing users
        );

        setState(() {
          _importPreviewData = preview;
          _transformationResult = transformationResult;  // Store transformation result
          _isProcessingFile = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse Excel file: $e';
        _isProcessingFile = false;
      });
    }
  }

  Future<void> _handleImport() async {
    if (_importPreviewData == null || !_importPreviewData!.canImport) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      // Get university path
      final universityPath = _cloudFunctionService.getCurrentUniversityPath();
      
      // Convert User objects back to Map for cloud function (matching developer settings format)
      final usersData = _importPreviewData!.usersToImport.map((user) => {
        'name': user.name,
        'email': user.email,
        'userType': user.userType,
        'student_id': user.studentId,
        'department': user.department,
        'year_major': user.yearMajor,
        'acknowledgment_signed': user.acknowledgmentSigned,
        'mentor': user.mentor, // Include mentor assignment for mentees
        'mentee': user.mentees ?? user.mentee, // Include mentee assignment for mentors
        'career_aspiration': user.careerAspiration, // Include career aspiration
        'topics': user.topics, // Include topics
        'import_source': user.importSource,
        'import_batch_id': user.importBatchId,
      }).toList();
      
      // Import users
      final result = await _cloudFunctionService.bulkCreateUsers(
        universityPath: universityPath,
        users: usersData,
      );

      // Create mentor assignments using the transformation result's mentorships (matching developer settings)
      if (_transformationResult != null && _transformationResult!.validMentorships.isNotEmpty) {
        print('🔄 Starting mentor assignments...');
        print('🔄 Valid mentorships: ${_transformationResult!.validMentorships.length}, Skipped: ${_transformationResult!.skippedMentorships.length}');
        
        // Use the same format as developer settings
        final mentorshipMappings = _transformationResult!.validMentorships.map((m) => m.toMap()).toList();
        
        final assignResult = await _cloudFunctionService.bulkAssignMentors(
          universityPath: universityPath,
          assignments: mentorshipMappings,
        );

        if (assignResult['success'] != true) {
          print('⚠️ Mentor assignment had issues: ${assignResult['message']}');
        } else {
          final assignResults = assignResult['results'];
          print('🔄 Mentor assignment completed: ${assignResults['success']} assignments made');
        }
      }

      final importResult = UserImportResult(
        successCount: result['successCount'] ?? 0,
        failureCount: result['failureCount'] ?? 0,
        successfulEmails: List<String>.from(result['successfulEmails'] ?? []),
        failedEmails: Map<String, String>.from(result['failedEmails'] ?? {}),
        mentorshipAssignmentsCreated: _transformationResult?.validMentorships.length ?? 0,
        importedAt: DateTime.now(),
      );

      setState(() {
        _lastImportResult = importResult;
        _importPreviewData = null;
        _transformationResult = null;  // Clear transformation result
        _isImporting = false;
      });

      // Reload users
      await _loadUsers();

      // Switch to user list tab
      _tabController.animateTo(1);

      // Show success message
      if (mounted) {
        // Show detailed success dialog (like developer settings)
        _showImportSuccessDialog(result, importResult);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to import users: $e';
        _isImporting = false;
      });
    }
  }

  Widget _buildParseResultsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: UserManagementConstants.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Excel Parse Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2D52),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fileName ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Statistics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Total Mentees', _parseResults!['totalMentees'].toString(), Colors.blue),
              _buildStatCard('Total Mentors', _parseResults!['totalMentors'].toString(), Colors.green),
              _buildStatCard('Unassigned', _parseResults!['unassigned'].toString(), Colors.orange),
            ],
          ),
          
          // Acknowledgment Status
          if (_parseResults!['acknowledgmentStatus'] != null) ...[
            const SizedBox(height: 24),
            Text(
              'Acknowledgment Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F2D52),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAckStatusCard('Signed', _parseResults!['acknowledgmentStatus']['yes'] ?? 0, Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAckStatusCard('Not Signed', _parseResults!['acknowledgmentStatus']['no'] ?? 0, Colors.red),
                ),
              ],
            ),
          ],
          
          // Top Topics
          if (_parseResults!['topTopics'] != null && (_parseResults!['topTopics'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Top Topics of Interest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F2D52),
              ),
            ),
            const SizedBox(height: 12),
            ...(_parseResults!['topTopics'] as List).take(5).map((topic) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: UserManagementConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topic['topic'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: UserManagementConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic['count'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: UserManagementConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactParseResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parse Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildCompactStatRow('Mentees', _parseResults!['totalMentees'].toString()),
          _buildCompactStatRow('Mentors', _parseResults!['totalMentors'].toString()),
          _buildCompactStatRow('Unassigned', _parseResults!['unassigned'].toString()),
          if (_parseResults!['acknowledgmentStatus'] != null) ...[
            const Divider(height: 16),
            _buildCompactStatRow('Signed', _parseResults!['acknowledgmentStatus']['yes'].toString()),
            _buildCompactStatRow('Not Signed', _parseResults!['acknowledgmentStatus']['no'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAckStatusCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            label == 'Signed' ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showImportSuccessDialog(Map<String, dynamic> createResult, UserImportResult importResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              importResult.isFullSuccess ? Icons.check_circle : Icons.warning,
              color: importResult.isFullSuccess ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(importResult.isFullSuccess ? 'Import Successful' : 'Import Completed with Issues'),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Import Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildResultRow('Users Created', importResult.successCount.toString(), Colors.green),
                    if (importResult.failureCount > 0)
                      _buildResultRow('Users Failed', importResult.failureCount.toString(), Colors.red),
                    const Divider(height: 16),
                    _buildResultRow('Mentorships Created', importResult.mentorshipAssignmentsCreated.toString(), Colors.blue),
                    if (_transformationResult != null && _transformationResult!.skippedMentorships.isNotEmpty)
                      _buildResultRow('Mentorships Skipped', _transformationResult!.skippedMentorships.length.toString(), Colors.orange),
                  ],
                ),
              ),
              
              // Warnings/Errors
              if (_transformationResult != null && _transformationResult!.hasWarnings) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Warnings (${_transformationResult!.warnings.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._transformationResult!.warnings.take(3).map((warning) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${warning.message}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (_transformationResult!.warnings.length > 3)
                        Text(
                          '... and ${_transformationResult!.warnings.length - 3} more',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Text(
                'You can view and manage imported users in the User List tab.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : (isTablet ? 32 : 24),
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              // Navigate back to coordinator dashboard
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const WebCoordinatorDashboardScreen(),
                                ),
                              );
                            },
                            tooltip: 'Back to Dashboard',
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                UserManagementConstants.screenTitle,
                                style: TextStyle(
                                  fontSize: isDesktop ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F2D52),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Import and manage users across the SMP program',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Premium Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: const Color(0xFF0F2D52),
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              height: 48,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(UserManagementConstants.uploadIcon, size: 20),
                                  SizedBox(width: 8),
                                  Text(UserManagementConstants.excelImportTab),
                                ],
                              ),
                            ),
                            Tab(
                              height: 48,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, size: 20),
                                  SizedBox(width: 8),
                                  Text(UserManagementConstants.userListTab),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab Content with proper constraints
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Excel Import Tab
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1200),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 48 : (isTablet ? 32 : 24)),
                        child: Column(
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: UserManagementConstants.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: UserManagementConstants.errorColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: UserManagementConstants.errorColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: UserManagementConstants.errorColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      },
                                      color: UserManagementConstants.errorColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Display filename and parse results after parsing
                            if (_fileName != null && _parseResults != null && _importPreviewData == null) ...[
                              _buildParseResultsSection(),
                              const SizedBox(height: 24),
                            ],
                            // Responsive layout for import and preview
                            if (isDesktop && _importPreviewData != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        ExcelUploadSection(
                                          onFileSelected: _handleFileUpload,
                                          isLoading: _isProcessingFile,
                                        ),
                                        if (_parseResults != null) ...[
                                          const SizedBox(height: 16),
                                          _buildCompactParseResults(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 3,
                                    child: ImportPreviewSection(
                                      previewData: _importPreviewData!,
                                      onImport: _handleImport,
                                      onCancel: () {
                                        setState(() {
                                          _importPreviewData = null;
                                          _transformationResult = null;
                                          _parseResults = null;
                                          _fileName = null;
                                        });
                                      },
                                      isLoading: _isImporting,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Stack layout for mobile/tablet or when no preview
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: _importPreviewData != null ? double.infinity : 800,
                                ),
                                child: Column(
                                  children: [
                                    ExcelUploadSection(
                                      onFileSelected: _handleFileUpload,
                                      isLoading: _isProcessingFile,
                                    ),
                                    // Display filename and parse results
                                    if (_fileName != null && _parseResults != null) ...[
                                      const SizedBox(height: 24),
                                      _buildParseResultsSection(),
                                    ],
                                    if (_importPreviewData != null) ...[
                                      const SizedBox(height: 24),
                                      ImportPreviewSection(
                                        previewData: _importPreviewData!,
                                        onImport: _handleImport,
                                        onCancel: () {
                                          setState(() {
                                            _importPreviewData = null;
                                            _transformationResult = null;
                                          });
                                        },
                                        isLoading: _isImporting,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // User List Tab
                  SingleChildScrollView(
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1200),
                        padding: EdgeInsets.all(isDesktop ? 48 : (isTablet ? 32 : 24)),
                        child: UserListSection(
                          users: _allUsers,
                          filter: _currentFilter,
                          onFilterChanged: (filter) {
                            setState(() {
                              _currentFilter = filter;
                            });
                          },
                          onRefresh: _loadUsers,
                          isLoading: _isLoadingUsers,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}