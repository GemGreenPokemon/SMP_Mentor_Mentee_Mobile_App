import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/developer_session.dart';
import '../utils/responsive.dart';
import '../services/excel_parser_service.dart';
import '../services/cloud_function_service.dart';
import '../services/auth_service.dart';
import '../services/direct_database_service.dart';
import 'firestore_manager_screen.dart';
import 'local_db_manager_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
          },
        ),
      ),
      body: Center(
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
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'French';
                });
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Location...'),
              trailing: const Icon(Icons.folder),
              onTap: () {
                // TODO: Implement custom location picker
                Navigator.pop(context);
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
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
                        
                        Navigator.pop(context);
                        
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
                        
                        Navigator.pop(context);
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
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'direct'),
            child: const Text('Direct (Test)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'cloud'),
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
    if (!_authService.isLoggedIn) {
      await _showLoginDialog();
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
                        
                        Navigator.pop(context);
                        
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
                        
                        Navigator.pop(context);
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

  // Show login dialog
  Future<void> _showLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF0F2D52)),
              SizedBox(width: 8),
              Text('Admin Login Required'),
            ],
          ),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Super admin credentials required to initialize database:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        await _authService.signInWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                        );

                        // Check if user has super admin role
                        final isSuperAdmin = await _authService.isSuperAdmin();
                        if (!isSuperAdmin) {
                          throw Exception('Super admin permissions required');
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged in successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Now proceed with database initialization
                        _showFirestoreInitializerDialog();
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Login failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
              ),
              child: isLoading
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
      ),
    );
  }
}