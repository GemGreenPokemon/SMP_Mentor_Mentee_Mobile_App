import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/settings_section_wrapper.dart';
import '../../../services/excel_parser_service.dart';
import '../../../models/mentorship.dart';

class ExcelUploadSection extends StatefulWidget {
  const ExcelUploadSection({super.key});

  @override
  State<ExcelUploadSection> createState() => _ExcelUploadSectionState();
}

class _ExcelUploadSectionState extends State<ExcelUploadSection> {
  final ExcelParserService _excelParser = ExcelParserService();
  bool _isLoading = false;
  String? _fileName;
  Map<String, dynamic>? _parseResults;
  
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
}