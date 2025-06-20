import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/settings_section_wrapper.dart';
import '../utils/settings_constants.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_parser_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_to_user_transformation_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/models/mentorship.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/developer_session.dart';

class ExcelUploadSection extends StatefulWidget {
  const ExcelUploadSection({super.key});

  @override
  State<ExcelUploadSection> createState() => _ExcelUploadSectionState();
}

class _ExcelUploadSectionState extends State<ExcelUploadSection> {
  final ExcelParserService _excelParser = ExcelParserService();
  final ExcelToUserTransformationService _transformationService = ExcelToUserTransformationService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  bool _isLoading = false;
  bool _isImporting = false;
  String? _fileName;
  Map<String, dynamic>? _parseResults;
  TransformationResult? _transformationResult;
  
  // Search variables
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPerson;
  final FocusNode _searchFocusNode = FocusNode();

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

    if (_selectedPerson != null && _searchController.text == _selectedPerson!['name']) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final searchTerm = _searchController.text.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Search mentees
    for (var assignment in _excelParser.getAllAssignments()) {
      if (assignment.mentee.toLowerCase().contains(searchTerm)) {
        // Get additional mentee info if available
        final menteeInfo = _getMenteeInfoByName(assignment.mentee);
        
        results.add({
          'name': assignment.mentee,
          'type': 'Mentee',
          'mentor': assignment.mentor,
          'acknowledgmentSigned': assignment.acknowledgmentSigned,
          'notes': assignment.notes,
          'email': menteeInfo?.email,
          'major': menteeInfo?.major,
          'year': menteeInfo?.year,
          'careerAspiration': menteeInfo?.careerAspiration,
          'topics': menteeInfo?.topics,
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
      _searchResults = results.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'Data Management',
      icon: Icons.upload_file,
      children: [
        Container(
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
                      backgroundColor: SettingsConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  // Import to Database button - only show if we have parse results and in developer mode
                  if (_parseResults != null && !_isLoading && DeveloperSession.isActive) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isImporting ? null : _handleImportToDatabase,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isImporting ? 'Importing...' : 'Import to Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
        ),
      ],
    );
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
          borderSide: BorderSide(color: SettingsConstants.primaryColor, width: 2),
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
                color: SettingsConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedPerson!['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SettingsConstants.primaryColor,
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
            if (_selectedPerson!['email'] != null &&
                _selectedPerson!['email'].toString().isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Email: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_selectedPerson!['email']),
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
            
            // Additional mentee information
            if (_selectedPerson!['major'] != null &&
                _selectedPerson!['major'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Major: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(_selectedPerson!['major']),
                  ),
                ],
              ),
            ],
            if (_selectedPerson!['year'] != null &&
                _selectedPerson!['year'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Year: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_selectedPerson!['year']),
                ],
              ),
            ],
            if (_selectedPerson!['careerAspiration'] != null &&
                _selectedPerson!['careerAspiration'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Career Aspiration: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(_selectedPerson!['careerAspiration']),
                  ),
                ],
              ),
            ],
            if (_selectedPerson!['topics'] != null &&
                _selectedPerson!['topics'] is List<String> &&
                (_selectedPerson!['topics'] as List<String>).isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Topics of Interest:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (_selectedPerson!['topics'] as List<String>).map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Text(
                          topic,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
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
          const Text(
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
          const Text(
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
            const Text(
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

        await _excelParser.parseExcelFile(result.files.single.bytes!);
        await _excelParser.parseMenteeAssignments();
        await _excelParser.parseMenteeInfo();

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

  /// Handle importing Excel data to the database
  Future<void> _handleImportToDatabase() async {
    if (_parseResults == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Excel data to import'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog first
    final confirmed = await _showImportConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Step 1: Transform Excel data to User model format
      print('🔄 Starting Excel to User transformation...');
      final assignments = _excelParser.getAllAssignments();
      final menteeInfo = _excelParser.getAllMenteeInfo();
      
      final transformationResult = _transformationService.transformToUsers(
        assignments, 
        menteeInfo,
        importBatchId: 'excel_import_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _transformationResult = transformationResult;
      });

      if (transformationResult.hasCriticalErrors) {
        throw Exception('Transformation failed with critical errors: ${transformationResult.errors.where((e) => e.isCritical).join(', ')}');
      }

      print('🔄 Transformation completed: ${transformationResult.users.length} users prepared');

      // Step 2: Bulk create users in database
      print('🔄 Starting bulk user creation...');
      final universityPath = _cloudFunctions.getCurrentUniversityPath();
      
      final createResult = await _cloudFunctions.bulkCreateUsers(
        universityPath: universityPath,
        users: transformationResult.users,
      );

      if (createResult['success'] != true) {
        throw Exception('User creation failed: ${createResult['message']}');
      }

      final userResults = createResult['results'];
      print('🔄 User creation completed: ${userResults['success']} users created, ${userResults['failed']} failed');

      // Step 3: Bulk assign mentors if we have valid mentorships
      if (transformationResult.validMentorships.isNotEmpty) {
        print('🔄 Starting mentor assignments...');
        print('🔄 Valid mentorships: ${transformationResult.validMentorships.length}, Skipped: ${transformationResult.skippedMentorships.length}');
        
        final mentorshipMappings = transformationResult.validMentorships.map((m) => m.toMap()).toList();
        
        final assignResult = await _cloudFunctions.bulkAssignMentors(
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

      // Show success message with details
      _showImportSuccessDialog(createResult, transformationResult);

    } catch (error) {
      print('❌ Import failed: $error');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// Show confirmation dialog before importing
  Future<bool> _showImportConfirmationDialog() async {
    final stats = _transformationService.getTransformationStats(
      _transformationService.transformToUsers(
        _excelParser.getAllAssignments(),
        _excelParser.getAllMenteeInfo(),
      )
    );

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.green),
            SizedBox(width: 8),
            Text('Import to Database'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will import the Excel data to the database:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Total Users:', '${stats.totalUsers}'),
              _buildStatRow('Mentors:', '${stats.mentors}'),
              _buildStatRow('Mentees:', '${stats.mentees}'),
              _buildStatRow('Total Mentorships:', '${stats.mentorships}'),
              _buildStatRow('Valid Mentorships:', '${stats.successfulMentorships}'),
              if (stats.skippedMentorships > 0)
                _buildStatRow('Skipped Mentorships:', '${stats.skippedMentorships}'),
              const SizedBox(height: 16),
              if (stats.warnings > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${stats.warnings} warnings detected. Check transformation details.',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Continue with import?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show success dialog with import results
  void _showImportSuccessDialog(Map<String, dynamic> createResult, TransformationResult transformationResult) {
    final userResults = createResult['results'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Import Successful!'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Excel data has been successfully imported to the database:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Users Created:', '${userResults['success']}'),
              if (userResults['failed'] > 0)
                _buildStatRow('Users Failed:', '${userResults['failed']}'),
              _buildStatRow('Mentorships Created:', '${transformationResult.validMentorships.length}'),
              if (transformationResult.skippedMentorships.isNotEmpty)
                _buildStatRow('Mentorships Skipped:', '${transformationResult.skippedMentorships.length}'),
              const SizedBox(height: 16),
              if (transformationResult.skippedMentorships.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${transformationResult.skippedMentorships.length} mentorships were skipped due to missing mentors. Mentees were created but need manual mentor assignment.',
                          style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'View the imported users in the User Management section.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a statistics row for dialogs
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Helper method to get mentee info by name
  MenteeInfo? _getMenteeInfoByName(String menteeName) {
    try {
      final allMenteeInfo = _excelParser.getAllMenteeInfo();
      print('🔍 Looking for mentee: "$menteeName"');
      print('🔍 Available mentees: ${allMenteeInfo.map((m) => m.name).toList()}');
      
      final found = allMenteeInfo.firstWhere(
        (info) => info.name.toLowerCase().trim() == menteeName.toLowerCase().trim(),
      );
      print('🔍 Found mentee info: ${found.name}, major: ${found.major}, year: ${found.year}');
      return found;
    } catch (e) {
      print('🔍 No mentee info found for: "$menteeName" - Error: $e');
      return null;
    }
  }

}