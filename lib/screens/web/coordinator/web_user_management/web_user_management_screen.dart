import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_parser_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_to_user_transformation_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/real_time_user_service.dart';
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
    with SingleTickerProviderStateMixin {
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
  ImportPreviewData? _importPreviewData;
  UserImportResult? _lastImportResult;
  List<User> _allUsers = [];
  UserFilter _currentFilter = UserFilter();
  StreamSubscription<List<User>>? _usersSubscription;

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
        });

        // Parse Excel file
        await _excelParser.parseExcelFile(result.files.single.bytes!);
        
        // Parse the sheets - MUST await these async operations
        await _excelParser.parseMenteeAssignments();
        await _excelParser.parseMenteeInfo();
        
        // Transform to users
        final transformationResult = _transformationService.transformToUsers(
          _excelParser.getAllAssignments(),
          _excelParser.getAllMenteeInfo(),
        );

        // Convert users to User objects
        final usersToImport = transformationResult.users.map((userData) {
          return User(
            id: userData['uid'] ?? '',
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            userType: userData['userType'] ?? 'mentee',
            createdAt: DateTime.now(),
            firebaseUid: userData['uid'],
            studentId: userData['studentId'],
            mentor: userData['mentor'],
            acknowledgmentSigned: userData['acknowledgmentSigned'] ?? 'not_applicable',
            department: userData['department'],
            yearMajor: userData['yearMajor'],
            careerAspiration: userData['careerAspiration'],
            topics: userData['topics'] != null ? List<String>.from(userData['topics']) : null,
            importSource: 'excel',
            importBatchId: DateTime.now().millisecondsSinceEpoch.toString(),
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
      
      // Convert User objects back to Map for cloud function
      final usersData = _importPreviewData!.usersToImport.map((user) => {
        'name': user.name,
        'email': user.email,
        'userType': user.userType,
        'studentId': user.studentId,
        'department': user.department,
        'yearMajor': user.yearMajor,
        'acknowledgmentSigned': user.acknowledgmentSigned,
      }).toList();
      
      // Import users
      final result = await _cloudFunctionService.bulkCreateUsers(
        universityPath: universityPath,
        users: usersData,
      );

      // Create mentor assignments
      final assignments = <Map<String, dynamic>>[];
      for (final assignment in _importPreviewData!.menteeAssignments) {
        if (assignment.mentor != null && assignment.mentor!.isNotEmpty) {
          final menteeUser = _importPreviewData!.usersToImport.firstWhere(
            (u) => u.name == assignment.mentee && u.userType == 'mentee',
            orElse: () => User(
              id: '',
              name: '',
              email: '',
              userType: '',
              createdAt: DateTime.now(),
            ),
          );
          final mentorUser = _importPreviewData!.usersToImport.firstWhere(
            (u) => u.name == assignment.mentor && u.userType == 'mentor',
            orElse: () => User(
              id: '',
              name: '',
              email: '',
              userType: '',
              createdAt: DateTime.now(),
            ),
          );

          if (menteeUser.id.isNotEmpty && mentorUser.id.isNotEmpty) {
            assignments.add({
              'mentorId': mentorUser.id,
              'menteeIds': [menteeUser.id],
            });
          }
        }
      }

      if (assignments.isNotEmpty) {
        await _cloudFunctionService.bulkAssignMentors(
          universityPath: universityPath,
          assignments: assignments,
        );
      }

      final importResult = UserImportResult(
        successCount: result['successCount'] ?? 0,
        failureCount: result['failureCount'] ?? 0,
        successfulEmails: List<String>.from(result['successfulEmails'] ?? []),
        failedEmails: Map<String, String>.from(result['failedEmails'] ?? {}),
        mentorshipAssignmentsCreated: assignments.length,
        importedAt: DateTime.now(),
      );

      setState(() {
        _lastImportResult = importResult;
        _importPreviewData = null;
        _isImporting = false;
      });

      // Reload users
      await _loadUsers();

      // Switch to user list tab
      _tabController.animateTo(1);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.summaryMessage),
            backgroundColor: importResult.isFullSuccess 
                ? UserManagementConstants.successColor 
                : UserManagementConstants.warningColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to import users: $e';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            onPressed: () => Navigator.of(context).pop(),
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
                            // Responsive layout for import and preview
                            if (isDesktop && _importPreviewData != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ExcelUploadSection(
                                      onFileSelected: _handleFileUpload,
                                      isLoading: _isProcessingFile,
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
                                    if (_importPreviewData != null) ...[
                                      const SizedBox(height: 24),
                                      ImportPreviewSection(
                                        previewData: _importPreviewData!,
                                        onImport: _handleImport,
                                        onCancel: () {
                                          setState(() {
                                            _importPreviewData = null;
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