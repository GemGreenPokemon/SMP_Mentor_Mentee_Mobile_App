import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/developer_session.dart';
import '../utils/responsive.dart';
import '../services/excel_parser_service.dart';
import '../services/cloud_function_service.dart';
import '../services/auth_service.dart';
import '../services/direct_database_service.dart';
import '../services/real_time_user_service.dart';
import '../models/user.dart';
import '../models/mentorship.dart';
import 'firestore_manager_screen.dart';
import 'local_db_manager_screen.dart';
import 'web_settings_login_screen.dart';
import 'dart:async';

class WebSettingsScreen extends StatefulWidget {
  final bool isMentor;
  const WebSettingsScreen({super.key, this.isMentor = true});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _downloadLocation = 'Default Downloads Folder';
  
  // Excel parser variables
  final ExcelParserService _excelParser = ExcelParserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _fileName;
  Map<String, dynamic>? _parseResults;
  
  // Search variables
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPerson;
  final FocusNode _searchFocusNode = FocusNode();
  
  // Firestore initializer variables
  String _selectedState = 'California';
  String _selectedCity = 'Merced';
  String _selectedCampus = 'UC_Merced';
  bool _isInitializing = false;
  
  // User management variables
  List<User> _usersList = [];
  bool _loadingUsers = false;
  bool _showAddUserForm = false;
  bool _showEditUserForm = false;
  User? _editingUser;
  bool _hasCheckedAuth = false;
  
  // Real-time user service
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  StreamSubscription<List<User>>? _usersStreamSubscription;
  
  // Auth overlay variables
  bool _showAuthOverlayFlag = false;
  bool _isAuthenticated = false;
  Function()? _pendingAuthAction;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DeveloperSession.isActive && !_hasCheckedAuth) {
      _hasCheckedAuth = true;
      _checkAuthAndLoadUsers();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    
    // Clean up real-time subscriptions
    _usersStreamSubscription?.cancel();
    _realTimeUserService.stopListening();
    
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty || _parseResults == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Don't search if the text matches the selected person
    if (_selectedPerson != null && _searchController.text == _selectedPerson!['name']) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Search for people
    final searchTerm = _searchController.text.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Search mentees
    for (var assignment in _excelParser.getAllAssignments()) {
      if (assignment.mentee.toLowerCase().contains(searchTerm)) {
        results.add({
          'name': assignment.mentee,
          'type': 'Mentee',
          'mentor': assignment.mentor,
          'acknowledgmentSigned': assignment.acknowledgmentSigned,
          'notes': assignment.notes,
        });
      }
    }

    // Search mentors
    for (var mentor in _excelParser.getAllMentors()) {
      if (mentor.toLowerCase().contains(searchTerm)) {
        var mentees = _excelParser.getAssignmentsByMentor(mentor);
        results.add({
          'name': mentor,
          'type': 'Mentor',
          'mentees': mentees,
        });
      }
    }

    setState(() {
      _searchResults = results.take(5).toList(); // Limit to 5 results
    });
    
    // Debug print
    print('Search term: $searchTerm, Found ${results.length} results');
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    double contentMaxWidth = isDesktop ? 800 : (isTablet ? 600 : double.infinity);

    return Stack(
      children: [
        // Main settings screen
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: const Color(0xFF0F2D52),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Use addPostFrameCallback to avoid Navigator re-entrance
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Check if we can pop (normal navigation)
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // If we can't pop, we likely came from developer menu
                    // Navigate to developer home if in developer mode, otherwise to login
                    if (DeveloperSession.isActive) {
                      Navigator.pushReplacementNamed(context, '/dev');
                    } else {
                      // Go to the appropriate dashboard based on user type
                      // For now, go to login as a safe fallback
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  }
                });
              },
            ),
          ),
          body: IgnorePointer(
            ignoring: _showAuthOverlayFlag,
            child: AnimatedOpacity(
              opacity: _showAuthOverlayFlag ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 24,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                _buildWebSection(
                  'Notifications',
                  Icons.notifications,
                  [
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive app notifications',
                      _notificationsEnabled,
                      (value) => setState(() => _notificationsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'Email Notifications',
                      'Receive email updates',
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Appearance',
                  Icons.palette,
                  [
                    _buildSwitchTile(
                      'Dark Mode',
                      'Toggle dark/light theme',
                      _darkMode,
                      (value) => setState(() => _darkMode = value),
                    ),
                    _buildListTile(
                      'Language',
                      _language,
                      Icons.language,
                      () => _showLanguageDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Files & Storage',
                  Icons.folder,
                  [
                    _buildListTile(
                      'Download Location',
                      _downloadLocation,
                      Icons.download,
                      () => _showDownloadLocationDialog(),
                    ),
                    _buildListTile(
                      'Clear Cache',
                      'Free up space by clearing cached data',
                      Icons.cleaning_services,
                      () => _showClearCacheDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Account',
                  Icons.person,
                  [
                    _buildListTile(
                      'Change Password',
                      null,
                      Icons.lock,
                      () {
                        // TODO: Implement change password
                      },
                    ),
                    _buildListTile(
                      'Privacy Settings',
                      null,
                      Icons.privacy_tip,
                      () {
                        // TODO: Implement privacy settings
                      },
                    ),
                    _buildListTile(
                      'Connected Accounts',
                      'Google Drive, OneDrive',
                      Icons.cloud,
                      () {
                        // TODO: Implement connected accounts
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildWebSection(
                  'Data Management',
                  Icons.upload_file,
                  [
                    _buildExcelUploadSection(),
                  ],
                ),
                if (DeveloperSession.isActive) ...[
                  const SizedBox(height: 24),
                  _buildWebSection(
                    'User Management',
                    Icons.person_add,
                    [
                      _buildUserManagementSection(),
                    ],
                  ),
                ],
                if (DeveloperSession.isActive) ...[
                  const SizedBox(height: 24),
                  _buildWebSection(
                    'Database Administration',
                    Icons.admin_panel_settings,
                    [
                      _buildListTile(
                        'Initialize Firestore Database',
                        'Configure state, city, and campus',
                        Icons.add_circle_outline,
                        () => _handleDatabaseInitialization(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _buildWebSection(
                  'Help & Support',
                  Icons.help,
                  [
                    _buildListTile(
                      'FAQ',
                      null,
                      Icons.question_answer,
                      () {
                        // TODO: Show FAQ
                      },
                    ),
                    _buildListTile(
                      'Contact Support',
                      null,
                      Icons.support_agent,
                      () {
                        // TODO: Show contact support options
                      },
                    ),
                    _buildListTile(
                      'About',
                      'Version 1.0.0',
                      Icons.info,
                      () {
                        // TODO: Show about dialog
                      },
                    ),
                  ],
                ),
                if (DeveloperSession.isActive) ...[
                  const SizedBox(height: 24),
                  _buildWebSection(
                    'Developer Tools',
                    Icons.developer_mode,
                    [
                      _buildListTile(
                        'Local DB Manager',
                        null,
                        Icons.storage,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocalDbManagerScreen(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        'Firestore Manager',
                        null,
                        Icons.cloud,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FirestoreManagerScreen(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        'Messaging Loopback Test',
                        null,
                        Icons.message,
                        () {
                          // TODO: Implement messaging loopback test UI
                        },
                      ),
                    ],
                  ),
                ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Auth overlay
        if (_showAuthOverlayFlag)
          _buildAuthOverlay(),
      ],
    );
  }

  Widget _buildWebSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF0F2D52)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F2D52),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F2D52),
      ),
    );
  }

  Widget _buildListTile(String title, String? subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F2D52)),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'French';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Download Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Default Downloads Folder'),
              trailing: _downloadLocation == 'Default Downloads Folder'
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Default Downloads Folder';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Documents Folder'),
              trailing: _downloadLocation == 'Documents Folder'
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Documents Folder';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Custom Location...'),
              trailing: const Icon(Icons.folder),
              onTap: () {
                // TODO: Implement custom location picker
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will free up space by removing cached data. Your saved files and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cache clearing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _fileName ?? 'No file selected',
                  style: TextStyle(
                    color: _fileName != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickExcelFile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isLoading ? 'Processing...' : 'Upload Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2D52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_parseResults != null) ...[
            const SizedBox(height: 24),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _buildSearchSection(),
                    if (_selectedPerson != null) ...[
                      const SizedBox(height: 24),
                      _buildPersonDetail(),
                    ],
                    const SizedBox(height: 24),
                    _buildParseResults(),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final person = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: person['type'] == 'Mentor'
                                    ? Colors.blue[100]
                                    : Colors.green[100],
                                child: Icon(
                                  person['type'] == 'Mentor'
                                      ? Icons.school
                                      : Icons.person,
                                  color: person['type'] == 'Mentor'
                                      ? Colors.blue[800]
                                      : Colors.green[800],
                                ),
                              ),
                              title: Text(person['name']),
                              subtitle: Text(person['type']),
                              onTap: () {
                                setState(() {
                                  _selectedPerson = person;
                                  _searchResults = [];
                                  _searchController.text = person['name'];
                                });
                                _searchFocusNode.unfocus();
                                print('Selected person: ${person['name']} (${person['type']})');
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParseResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Excel Parse Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2D52),
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow('Total Mentees', _parseResults!['totalMentees'].toString()),
          _buildResultRow('Total Mentors', _parseResults!['totalMentors'].toString()),
          _buildResultRow('Unassigned Mentees', _parseResults!['unassigned'].toString()),
          const SizedBox(height: 12),
          Text(
            'Acknowledgment Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2D52),
            ),
          ),
          const SizedBox(height: 8),
          _buildResultRow('Signed', _parseResults!['acknowledgmentStatus']['Yes'].toString()),
          _buildResultRow('Not Signed', _parseResults!['acknowledgmentStatus']['No'].toString()),
          if (_parseResults!['topTopics'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Top Topics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F2D52),
              ),
            ),
            const SizedBox(height: 8),
            ...(_parseResults!['topTopics'] as Map<String, int>)
                .entries
                .take(5)
                .map((entry) => _buildResultRow(entry.key, entry.value.toString())),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
        });

        // Parse the Excel file
        await _excelParser.parseExcelFile(result.files.single.bytes!);
        
        // Parse assignments and info
        await _excelParser.parseMenteeAssignments();
        await _excelParser.parseMenteeInfo();

        // Get statistics
        var acknowledgmentStatus = _excelParser.getAcknowledgmentStatus();
        var topicStats = _excelParser.getTopicStatistics();
        var unassignedMentees = _excelParser.getUnassignedMentees();
        var allMentors = _excelParser.getAllMentors();
        var allMentees = _excelParser.getAllMentees();

        setState(() {
          _parseResults = {
            'totalMentees': allMentees.length,
            'totalMentors': allMentors.length,
            'unassigned': unassignedMentees.length,
            'acknowledgmentStatus': acknowledgmentStatus,
            'topTopics': topicStats,
          };
          _isLoading = false;
          _searchController.clear();
          _selectedPerson = null;
          _searchResults = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file parsed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing Excel file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchSection() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search for mentors or mentees...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedPerson = null;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
        ),
      ),
      onSubmitted: (value) {
        if (_searchResults.isNotEmpty) {
          setState(() {
            _selectedPerson = _searchResults.first;
            _searchResults = [];
            _searchController.text = _selectedPerson!['name'];
          });
          _searchFocusNode.unfocus();
        }
      },
    );
  }

  Widget _buildPersonDetail() {
    if (_selectedPerson == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _selectedPerson!['type'] == 'Mentor' ? Icons.school : Icons.person,
                color: const Color(0xFF0F2D52),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedPerson!['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2D52),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedPerson!['type'] == 'Mentor'
                      ? Colors.blue[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPerson!['type'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedPerson!['type'] == 'Mentor'
                        ? Colors.blue[800]
                        : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedPerson!['type'] == 'Mentor') ...[
            Text(
              'Mentees (${_selectedPerson!['mentees'].length}):',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...(_selectedPerson!['mentees'] as List<MenteeAssignment>).map((mentee) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(mentee.mentee),
                    ),
                    if (mentee.acknowledgmentSigned)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            if (_selectedPerson!['mentor'] != null) ...[
              Row(
                children: [
                  const Text(
                    'Mentor: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_selectedPerson!['mentor']),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Text(
                  'Acknowledgment: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Icon(
                  _selectedPerson!['acknowledgmentSigned']
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 16,
                  color: _selectedPerson!['acknowledgmentSigned']
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedPerson!['acknowledgmentSigned'] ? 'Signed' : 'Not Signed',
                  style: TextStyle(
                    color: _selectedPerson!['acknowledgmentSigned']
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            if (_selectedPerson!['notes'] != null &&
                _selectedPerson!['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(_selectedPerson!['notes']),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showFirestoreInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.cloud_upload, color: Color(0xFF0F2D52)),
              const SizedBox(width: 8),
              const Text('Initialize Firestore Database'),
            ],
          ),
          content: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text(
                  'Configure your database location before initialization:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // State Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: ['California'].map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedState = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // City Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: ['Merced', 'Fresno', 'Berkeley', 'Los Angeles']
                              .map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCity = value!;
                              // Update campus options based on city
                              _updateCampusSelection(value);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campus Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campus',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCampus,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: _getCampusOptions(_selectedCity).map((campus) {
                            return DropdownMenuItem(
                              value: campus['value'] as String,
                              child: Text(campus['display'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCampus = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Preview Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Database Structure Preview:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F2D52),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_selectedState/',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              '  └── $_selectedCity/',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              '      └── $_selectedCampus/',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            const Text(
                              '          ├── users/',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            const Text(
                              '          ├── meetings/',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            const Text(
                              '          ├── announcements/',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            const Text(
                              '          └── ... (all collections)',
                              style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Collection Details
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '          └── users/ (collection)',
                              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.amber[700]),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '              ├── {userId}/ (document)',
                              style: TextStyle(fontFamily: 'monospace', color: Colors.blue),
                            ),
                            const Text(
                              '              │   ├── id: String',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── name: String',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── email: String (unique)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── userType: "mentor" | "mentee" | "coordinator"',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── student_id: String (e.g., "JS12345")',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── mentor: String (mentor\'s student_id)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── mentee: String (JSON array of mentee IDs)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── department: String',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── year_major: String',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── acknowledgment_signed: "yes" | "no" | "not_applicable"',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── created_at: Timestamp',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   │',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const Text(
                              '              │   ├── checklists/ (subcollection)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                            ),
                            const Text(
                              '              │   ├── availability/ (subcollection)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                            ),
                            const Text(
                              '              │   ├── messages/ (subcollection)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                            ),
                            const Text(
                              '              │   ├── notes/ (subcollection)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                            ),
                            const Text(
                              '              │   └── ratings/ (subcollection)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange),
                            ),
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
          actions: [
            TextButton(
              onPressed: _isInitializing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isInitializing
                  ? null
                  : () async {
                      setDialogState(() {
                        _isInitializing = true;
                      });
                      
                      try {
                        // Get the university name from campus options
                        final campusOptions = _getCampusOptions(_selectedCity);
                        final selectedCampusData = campusOptions.firstWhere(
                          (option) => option['value'] == _selectedCampus,
                          orElse: () => {'name': _selectedCampus},
                        );
                        final universityName = selectedCampusData['name'] ?? _selectedCampus;
                        
                        // Use direct database service to bypass CORS issues
                        Map<String, dynamic> result;
                        try {
                          result = await DirectDatabaseService.instance.initializeUniversityDirect(
                            state: _selectedState,
                            city: _selectedCity,
                            campus: _selectedCampus,
                            universityName: universityName,
                          );
                        } catch (e) {
                          throw Exception('Database Error: ${e.toString()}');
                        }
                        
                        setDialogState(() {
                          _isInitializing = false;
                        });
                        
                        // Use addPostFrameCallback to avoid Navigator re-entrance
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pop(context);
                        });
                        
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Database initialized successfully!'),
                                  Text('Path: ${result['universityPath']}'),
                                  Text('Collections: ${(result['collections'] as List).length} created'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else {
                          throw Exception(result['message'] ?? 'Unknown error occurred');
                        }
                      } catch (e) {
                        setDialogState(() {
                          _isInitializing = false;
                        });
                        
                        // Use addPostFrameCallback to avoid Navigator re-entrance
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pop(context);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to initialize database: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
              ),
              child: _isInitializing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Initialize Database'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCampusSelection(String city) {
    // Reset campus selection based on city
    switch (city) {
      case 'Merced':
        _selectedCampus = 'UC_Merced';
        break;
      case 'Fresno':
        _selectedCampus = 'Fresno_State';
        break;
      case 'Berkeley':
        _selectedCampus = 'UC_Berkeley';
        break;
      case 'Los Angeles':
        _selectedCampus = 'UCLA';
        break;
    }
  }

  List<Map<String, String>> _getCampusOptions(String city) {
    switch (city) {
      case 'Merced':
        return [
          {'value': 'UC_Merced', 'display': 'UC Merced', 'name': 'University of California, Merced'},
          {'value': 'Merced_College', 'display': 'Merced College', 'name': 'Merced College'},
        ];
      case 'Fresno':
        return [
          {'value': 'Fresno_State', 'display': 'Fresno State', 'name': 'California State University, Fresno'},
          {'value': 'Fresno_City_College', 'display': 'Fresno City College', 'name': 'Fresno City College'},
        ];
      case 'Berkeley':
        return [
          {'value': 'UC_Berkeley', 'display': 'UC Berkeley', 'name': 'University of California, Berkeley'},
          {'value': 'Berkeley_City_College', 'display': 'Berkeley City College', 'name': 'Berkeley City College'},
        ];
      case 'Los Angeles':
        return [
          {'value': 'UCLA', 'display': 'UCLA', 'name': 'University of California, Los Angeles'},
          {'value': 'USC', 'display': 'USC', 'name': 'University of Southern California'},
          {'value': 'LA_City_College', 'display': 'LA City College', 'name': 'Los Angeles City College'},
        ];
      default:
        return [];
    }
  }

  // Handle database initialization with Cloud Functions
  Future<void> _handleDatabaseInitialization() async {
    // Show options dialog - Cloud Function vs Direct (for testing)
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Color(0xFF0F2D52)),
            SizedBox(width: 8),
            Text('Initialize Database'),
          ],
        ),
        content: const Text(
          'Choose initialization method:\n\n'
          '• Cloud Function: Secure, authenticated\n'
          '• Direct: Development testing only',
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context, 'cancel');
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context, 'direct');
              });
            },
            child: const Text('Direct (Test)'),
          ),
          ElevatedButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context, 'cloud');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
            ),
            child: const Text('Cloud Function'),
          ),
        ],
      ),
    );

    if (choice == 'cloud') {
      await _handleCloudFunctionInit();
    } else if (choice == 'direct') {
      _showFirestoreInitializerDialog();
    }
  }

  // Handle Cloud Function initialization with authentication
  Future<void> _handleCloudFunctionInit() async {
    // Check if user is authenticated
    if (_requiresAuth()) {
      _showAuthOverlay(onSuccess: () {
        _showCloudFunctionInitializerDialog();
      });
      return;
    }

    // Check if user has super admin permissions
    final isSuperAdmin = await _authService.isSuperAdmin();
    if (!isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super admin permissions required for database initialization'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with Cloud Function initialization
    _showCloudFunctionInitializerDialog();
  }

  void _showCloudFunctionInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.cloud, color: Color(0xFF0F2D52)),
              const SizedBox(width: 8),
              const Text('Initialize with Cloud Function'),
            ],
          ),
          content: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text(
                  'Configure your database location (secure Cloud Function):',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // State Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: ['California'].map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedState = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // City Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: ['Merced', 'Fresno', 'Berkeley', 'Los Angeles']
                              .map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCity = value!;
                              // Update campus options based on city
                              _updateCampusSelection(value);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campus Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campus',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCampus,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: _getCampusOptions(_selectedCity).map((campus) {
                            return DropdownMenuItem(
                              value: campus['value'] as String,
                              child: Text(campus['display'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCampus = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Secure Cloud Function',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '✓ Authenticated with super admin permissions\n'
                        '✓ Server-side validation and security\n'
                        '✓ Proper error handling and logging',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isInitializing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isInitializing
                  ? null
                  : () async {
                      setDialogState(() {
                        _isInitializing = true;
                      });
                      
                      try {
                        // Get the university name from campus options
                        final campusOptions = _getCampusOptions(_selectedCity);
                        final selectedCampusData = campusOptions.firstWhere(
                          (option) => option['value'] == _selectedCampus,
                          orElse: () => {'name': _selectedCampus},
                        );
                        final universityName = selectedCampusData['name'] ?? _selectedCampus;
                        
                        // Call the cloud function to initialize the database
                        Map<String, dynamic> result;
                        try {
                          result = await _cloudFunctions.initializeUniversity(
                            state: _selectedState,
                            city: _selectedCity,
                            campus: _selectedCampus,
                            universityName: universityName,
                          );
                        } on FirebaseFunctionsException catch (e) {
                          if (e.code == 'cors') {
                            throw Exception('CORS Error: Please ensure you are authenticated and try again.');
                          }
                          throw Exception('Firebase Functions Error: ${e.code} - ${e.message}');
                        } catch (e) {
                          throw Exception('Network Error: ${e.toString()}');
                        }
                        
                        setDialogState(() {
                          _isInitializing = false;
                        });
                        
                        // Use addPostFrameCallback to avoid Navigator re-entrance
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pop(context);
                        });
                        
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Database initialized successfully via Cloud Function!'),
                                  Text('Path: ${result['universityPath']}'),
                                  Text('Collections: ${(result['collections'] as List).length} created'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else {
                          throw Exception(result['message'] ?? 'Unknown error occurred');
                        }
                      } catch (e) {
                        setDialogState(() {
                          _isInitializing = false;
                        });
                        
                        // Use addPostFrameCallback to avoid Navigator re-entrance
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pop(context);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to initialize database: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
              ),
              child: _isInitializing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Initialize via Cloud Function'),
            ),
          ],
        ),
      ),
    );
  }

  // Show auth overlay
  void _showAuthOverlay({Function()? onSuccess}) {
    setState(() {
      _showAuthOverlayFlag = true;
      _pendingAuthAction = onSuccess;
    });
  }
  
  // Check if authenticated
  bool _requiresAuth() {
    return !_isAuthenticated && !_authService.isLoggedIn;
  }

  // Check authentication and load users
  Future<void> _checkAuthAndLoadUsers() async {
    if (!mounted) return;
    
    // Check if user is authenticated
    if (_requiresAuth()) {
      _showAuthOverlay(onSuccess: () async {
        await _loadUsers();
      });
      return;
    }

    // Check if user has coordinator permissions
    final isCoordinator = await _authService.isSuperAdmin(); // Using super admin for now
    if (!isCoordinator) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coordinator permissions required for user management'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Load users if authenticated
    await _loadUsers();
  }

  // Load users from database
  Future<void> _loadUsers() async {
    print('🔍 _loadUsers: Starting user loading (testing both methods)');
    if (mounted) {
      setState(() {
        _loadingUsers = true;
      });
    }

    try {
      final universityPath = _cloudFunctions.getCurrentUniversityPath();
      print('🔍 _loadUsers: Using universityPath: $universityPath');
      
      // TEST 1: Try cloud function first (old method)
      print('🔍 _loadUsers: Testing cloud function method...');
      try {
        final result = await _cloudFunctions.getUsersList(
          universityPath: universityPath,
        );
        print('🔍 _loadUsers: Cloud function result: $result');
        
        if (result['success'] == true) {
          final usersData = (result['data'] as List<dynamic>?) ?? [];
          print('🔍 _loadUsers: Cloud function found ${usersData.length} users');
        }
      } catch (e) {
        print('🔍 _loadUsers: Cloud function error: $e');
      }
      
      // TEST 2: Try real-time method
      print('🔍 _loadUsers: Testing real-time method...');
      
      // Cancel any existing subscription
      await _usersStreamSubscription?.cancel();
      
      // Start listening to real-time updates
      _realTimeUserService.startListening(universityPath);
      
      // Subscribe to user updates
      _usersStreamSubscription = _realTimeUserService.usersStream.listen(
        (List<User> users) {
          print('🔍 _loadUsers: Received real-time update with ${users.length} users');
          if (mounted) {
            setState(() {
              _usersList = users;
              _loadingUsers = false;
            });
            
            // Show success message
            if (users.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔥 Real-time mode: ${users.length} users loaded'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔥 Real-time listening active, but no users found at: $universityPath/data/users'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
        onError: (error) {
          print('🔍 _loadUsers: Real-time error: $error');
          if (mounted) {
            setState(() {
              _loadingUsers = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Real-time error: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
      
      // If we already have cached users, show them immediately
      final cachedUsers = _realTimeUserService.currentUsers;
      if (cachedUsers.isNotEmpty && mounted) {
        setState(() {
          _usersList = cachedUsers;
          _loadingUsers = false;
        });
      }
      
      print('🔍 _loadUsers: Real-time listening started successfully');
    } catch (e) {
      print('🔍 _loadUsers: Error starting real-time updates: $e');
      if (mounted) {
        setState(() {
          _usersList = [];
          _loadingUsers = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting real-time updates: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Build user management section
  Widget _buildUserManagementSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Authorized Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F2D52),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_showAddUserForm) {
                    setState(() => _showAddUserForm = false);
                  } else {
                    // Check authentication before showing form
                    if (_requiresAuth()) {
                      _showAuthOverlay(onSuccess: () {
                        setState(() => _showAddUserForm = true);
                      });
                      return;
                    }
                    final isCoordinator = await _authService.isSuperAdmin();
                    if (!isCoordinator) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coordinator permissions required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() => _showAddUserForm = true);
                  }
                },
                icon: Icon(_showAddUserForm ? Icons.close : Icons.person_add),
                label: Text(_showAddUserForm ? 'Cancel' : 'Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2D52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add user form
          if (_showAddUserForm) ...[
            _buildAddUserForm(),
            const SizedBox(height: 24),
          ],
          
          // Edit user form
          if (_showEditUserForm && _editingUser != null) ...[
            _buildEditUserForm(),
            const SizedBox(height: 24),
          ],
          
          // Users list
          _buildUsersList(),
        ],
      ),
    );
  }

  // Build add user form
  Widget _buildAddUserForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final studentIdController = TextEditingController();
    final departmentController = TextEditingController();
    final yearMajorController = TextEditingController();
    String selectedUserType = 'mentee';
    String selectedAcknowledgment = 'not_applicable';
    String? selectedMentor;
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setFormState) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2D52),
              ),
            ),
            const SizedBox(height: 16),
            
            // Form fields with responsive layout to avoid overflow
            Column(
              children: [
                // Row 1: Name and Email - Make responsive
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Row 2: Student ID and User Type - Make responsive
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUserType,
                          decoration: const InputDecoration(
                            labelText: 'User Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                            DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                            DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                          ],
                          onChanged: (value) {
                            setFormState(() {
                              selectedUserType = value!;
                              if (selectedUserType != 'mentee') {
                                selectedAcknowledgment = 'not_applicable';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'User Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                          DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                          DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                        ],
                        onChanged: (value) {
                          setFormState(() {
                            selectedUserType = value!;
                            if (selectedUserType != 'mentee') {
                              selectedAcknowledgment = 'not_applicable';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Row 3: Department and Year/Major - Make responsive
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: yearMajorController,
                          decoration: const InputDecoration(
                            labelText: 'Year & Major',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grade),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: yearMajorController,
                        decoration: const InputDecoration(
                          labelText: 'Year & Major',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Conditional fields based on user type
            if (selectedUserType == 'mentee') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedAcknowledgment,
                      decoration: const InputDecoration(
                        labelText: 'Acknowledgment Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'yes', child: Text('Signed')),
                        DropdownMenuItem(value: 'no', child: Text('Not Signed')),
                        DropdownMenuItem(value: 'not_applicable', child: Text('Not Applicable')),
                      ],
                      onChanged: (value) {
                        setFormState(() {
                          selectedAcknowledgment = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: selectedMentor,
                      decoration: const InputDecoration(
                        labelText: 'Assign Mentor (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.supervisor_account),
                      ),
                      isExpanded: true, // This fixes the overflow
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Mentor Assigned')),
                        // TODO: Populate with actual mentors
                        ..._usersList
                            .where((user) => user.userType == 'mentor')
                            .map((mentor) => DropdownMenuItem(
                                  value: mentor.studentId ?? mentor.id,
                                  child: Text(
                                    mentor.name,
                                    overflow: TextOverflow.ellipsis, // Handle long names
                                  ),
                                ))
                            .toList(),
                      ],
                      onChanged: (value) {
                        setFormState(() {
                          selectedMentor = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Submit button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSubmitting ? null : () {
                    nameController.clear();
                    emailController.clear();
                    studentIdController.clear();
                    departmentController.clear();
                    yearMajorController.clear();
                    setState(() => _showAddUserForm = false);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty || 
                        emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Email are required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setFormState(() => isSubmitting = true);

                    try {
                      // TODO: Implement actual user creation
                      await _createUser(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        userType: selectedUserType,
                        studentId: studentIdController.text.trim().isEmpty 
                            ? null : studentIdController.text.trim(),
                        department: departmentController.text.trim().isEmpty 
                            ? null : departmentController.text.trim(),
                        yearMajor: yearMajorController.text.trim().isEmpty 
                            ? null : yearMajorController.text.trim(),
                        acknowledgmentSigned: selectedAcknowledgment,
                        mentor: selectedMentor,
                      );

                      // Clear form and hide it
                      nameController.clear();
                      emailController.clear();
                      studentIdController.clear();
                      departmentController.clear();
                      yearMajorController.clear();
                      if (mounted) setState(() => _showAddUserForm = false);
                      
                      // Reload users list
                      await _loadUsers();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding user: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setFormState(() => isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2D52),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditUserForm() {
    return StatefulBuilder(
      builder: (context, setState) {
        // Form controllers with pre-populated data
        final nameController = TextEditingController(text: _editingUser?.name ?? '');
        final emailController = TextEditingController(text: _editingUser?.email ?? '');
        final studentIdController = TextEditingController(text: _editingUser?.studentId ?? '');
        final departmentController = TextEditingController(text: _editingUser?.department ?? '');
        final yearMajorController = TextEditingController(text: _editingUser?.yearMajor ?? '');
        
        String selectedUserType = _editingUser?.userType ?? 'mentee';
        String selectedAcknowledgment = _editingUser?.acknowledgmentSigned ?? 'not_applicable';
        String? selectedMentor = _editingUser?.mentor;
        bool isSubmitting = false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Edit User: ${_editingUser?.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 1: Name and Email
              Responsive.isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),

              // Row 2: Student ID and User Type
              Responsive.isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: studentIdController,
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUserType,
                            decoration: const InputDecoration(
                              labelText: 'User Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                              DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                              DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedUserType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedUserType,
                          decoration: const InputDecoration(
                            labelText: 'User Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                            DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                            DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedUserType = value!;
                            });
                          },
                        ),
                      ],
                    ),
              const SizedBox(height: 16),

              // Row 3: Department and Year/Major
              Responsive.isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: departmentController,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: yearMajorController,
                            decoration: const InputDecoration(
                              labelText: 'Year/Major',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: yearMajorController,
                          decoration: const InputDecoration(
                            labelText: 'Year/Major',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),

              // Mentee-specific fields
              if (selectedUserType == 'mentee') ...[
                const SizedBox(height: 16),
                
                // Acknowledgment Status
                DropdownButtonFormField<String>(
                  value: selectedAcknowledgment,
                  decoration: const InputDecoration(
                    labelText: 'Acknowledgment Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'not_applicable', child: Text('Not Applicable')),
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'no', child: Text('No')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedAcknowledgment = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Mentor Assignment
                DropdownButtonFormField<String>(
                  value: selectedMentor,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Mentor',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Mentor Assigned')),
                    ..._usersList
                        .where((user) => user.userType == 'mentor')
                        .map((mentor) => DropdownMenuItem(
                              value: mentor.id,
                              child: Text(mentor.name),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMentor = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSubmitting ? null : () {
                      setState(() {
                        _showEditUserForm = false;
                        _editingUser = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      // Validate required fields
                      if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name and Email are required'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isSubmitting = true;
                      });

                      try {
                        await _updateUser(
                          userId: _editingUser!.id,
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          userType: selectedUserType,
                          studentId: studentIdController.text.trim().isEmpty ? null : studentIdController.text.trim(),
                          department: departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
                          yearMajor: yearMajorController.text.trim().isEmpty ? null : yearMajorController.text.trim(),
                          acknowledgmentSigned: selectedAcknowledgment,
                          mentorId: selectedMentor,
                        );

                        setState(() {
                          _showEditUserForm = false;
                          _editingUser = null;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          isSubmitting = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating user: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update User'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Build users list
  Widget _buildUsersList() {
    if (_loadingUsers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_usersList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add users manually or upload an Excel file to get started',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 16),
                const Expanded(flex: 2, child: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          ),
          
          // User rows
          ...(_usersList.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Colors.grey[25],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        if (user.studentId != null)
                          Text(
                            'ID: ${user.studentId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      user.email,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUserTypeColor(user.userType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.userType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      user.department ?? '-',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: _getStatusColor(user),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getStatusText(user),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(user),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _editUser(user),
                          tooltip: 'Edit User',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () => _deleteUser(user),
                          tooltip: 'Delete User',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'mentor':
        return Colors.blue;
      case 'mentee':
        return Colors.green;
      case 'coordinator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(User user) {
    // TODO: Implement logic to check if user has Firebase Auth account
    return Colors.orange; // For now, assume all are pending
  }

  String _getStatusText(User user) {
    // TODO: Implement logic to check if user has Firebase Auth account
    return 'Pending'; // For now, assume all are pending
  }

  Future<void> _createUser({
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentor,
  }) async {
    final universityPath = _cloudFunctions.getCurrentUniversityPath();
    
    // Create the user first
    final result = await _cloudFunctions.createUserAccount(
      universityPath: universityPath,
      name: name,
      email: email,
      userType: userType,
      studentId: studentId,
      department: department,
      yearMajor: yearMajor,
      acknowledgmentSigned: acknowledgmentSigned,
    );

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to create user');
    }

    // If this is a mentee and mentor is assigned, create mentorship
    if (userType == 'mentee' && mentor != null && result['data'] != null) {
      try {
        final newUserId = result['data']['id'];
        await _cloudFunctions.assignMentor(
          universityPath: universityPath,
          mentorId: mentor,
          menteeId: newUserId,
        );
      } catch (e) {
        // Log the error but don't fail the user creation
        print('Warning: Failed to assign mentor: $e');
      }
    }
  }

  Future<void> _updateUser({
    required String userId,
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentorId,
  }) async {
    final universityPath = _cloudFunctions.getCurrentUniversityPath();
    
    // Use the real-time service to update the user directly in Firestore
    final updateData = <String, dynamic>{
      'name': name,
      'email': email,
      'userType': userType,
      'acknowledgment_signed': acknowledgmentSigned,
    };
    
    // Add optional fields only if they have values
    if (studentId != null && studentId.isNotEmpty) {
      updateData['student_id'] = studentId;
    }
    if (department != null && department.isNotEmpty) {
      updateData['department'] = department;
    }
    if (yearMajor != null && yearMajor.isNotEmpty) {
      updateData['year_major'] = yearMajor;
    }
    
    // Handle mentor assignment for mentees
    if (userType == 'mentee') {
      updateData['mentor'] = mentorId; // Can be null to unassign
    }
    
    // Update the user using the real-time service
    final success = await _realTimeUserService.updateUser(
      universityPath,
      userId,
      updateData,
    );
    
    if (!success) {
      throw Exception('Failed to update user in database');
    }
    
    // If mentor assignment changed for a mentee, handle mentorship relationship
    if (userType == 'mentee') {
      try {
        // Note: For simplicity, we're just updating the user's mentor field
        // In a production app, you might want to handle mentorship relationships
        // more comprehensively through cloud functions
        print('Mentor assignment updated for mentee: $mentorId');
      } catch (e) {
        print('Warning: Failed to update mentorship relationship: $e');
      }
    }
  }

  void _editUser(User user) {
    setState(() {
      _editingUser = user;
      _showEditUserForm = true;
      _showAddUserForm = false; // Close add form if open
    });
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this user?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(user.email),
                  Text('Type: ${user.userType}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Use addPostFrameCallback to avoid Navigator re-entrance
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              
              try {
                final universityPath = _cloudFunctions.getCurrentUniversityPath();
                final result = await _cloudFunctions.deleteUserAccount(
                  universityPath: universityPath,
                  userId: user.id,
                );

                if (result['success'] == true) {
                  await _loadUsers(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception(result['message'] ?? 'Failed to delete user');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // Build auth overlay widget
  Widget _buildAuthOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: _AuthOverlayContent(
              onAuthSuccess: () {
                setState(() {
                  _isAuthenticated = true;
                  _showAuthOverlayFlag = false;
                });
                
                // Execute pending action if any
                if (_pendingAuthAction != null) {
                  _pendingAuthAction!();
                  _pendingAuthAction = null;
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged in successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onCancel: () {
                setState(() {
                  _showAuthOverlayFlag = false;
                  _pendingAuthAction = null;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Auth overlay content widget
class _AuthOverlayContent extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback onCancel;
  
  const _AuthOverlayContent({
    Key? key,
    required this.onAuthSuccess,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  State<_AuthOverlayContent> createState() => _AuthOverlayContentState();
}

class _AuthOverlayContentState extends State<_AuthOverlayContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _loginSuccess = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    // Clear focus first
    FocusScope.of(context).unfocus();
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Authenticate with Firebase Auth
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Check if user has super admin role
      final isSuperAdmin = await _authService.isSuperAdmin();
      
      if (!isSuperAdmin) {
        throw Exception('Super admin permissions required');
      }
      
      // Show success state
      setState(() {
        _loginSuccess = true;
        _isLoading = false;
      });
      
      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Call success callback
      widget.onAuthSuccess();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loginSuccess) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Login Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Loading settings...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.admin_panel_settings,
          size: 64,
          color: Color(0xFF0F2D52),
        ),
        const SizedBox(height: 24),
        const Text(
          'Admin Login Required',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2D52),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Super admin credentials required to access settings',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ],
    );
  }
}