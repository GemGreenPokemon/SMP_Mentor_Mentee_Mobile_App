import 'dart:typed_data';
import 'package:excel/excel.dart';

class MenteeAssignment {
  final String mentee;
  final String? mentor;
  final bool acknowledgmentSigned;
  final String? notes;

  MenteeAssignment({
    required this.mentee,
    this.mentor,
    required this.acknowledgmentSigned,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'mentee': mentee,
    'mentor': mentor,
    'acknowledgment_signed': acknowledgmentSigned,
    'notes': notes,
  };
}

class MenteeInfo {
  final String name;
  final String email;
  final String major;
  final String year;
  final String careerAspiration;
  final List<String> topics;

  MenteeInfo({
    required this.name,
    required this.email,
    required this.major,
    required this.year,
    required this.careerAspiration,
    required this.topics,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'major': major,
    'year': year,
    'career_aspiration': careerAspiration,
    'topics': topics,
  };
}

class ExcelParserService {
  Excel? _excel;
  List<MenteeAssignment> _assignments = [];
  List<MenteeInfo> _menteeInfoList = [];

  // Parse Excel file from bytes
  Future<void> parseExcelFile(Uint8List bytes) async {
    _excel = Excel.decodeBytes(bytes);
    _assignments.clear();
    _menteeInfoList.clear();
  }

  // Parse Mentee Assignments sheet
  Future<List<MenteeAssignment>> parseMenteeAssignments() async {
    if (_excel == null) return [];

    var sheet = _excel!.tables['Mentee Assignments'];
    if (sheet == null) return [];

    _assignments.clear();
    
    // Skip header row
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isEmpty || row[0]?.value == null) continue;

      String mentee = row[0]?.value?.toString() ?? '';
      String? mentor = row[1]?.value?.toString();
      String? ackStatus = row[2]?.value?.toString();
      String? notes = row[3]?.value?.toString();

      bool acknowledgmentSigned = ackStatus?.toLowerCase() == 'yes' || 
                                  ackStatus?.toLowerCase() == 'signed';

      if (mentee.isNotEmpty) {
        _assignments.add(MenteeAssignment(
          mentee: mentee,
          mentor: mentor,
          acknowledgmentSigned: acknowledgmentSigned,
          notes: notes,
        ));
      }
    }

    return _assignments;
  }

  // Parse Mentee Info for Matching sheet
  Future<List<MenteeInfo>> parseMenteeInfo() async {
    if (_excel == null) return [];

    var sheet = _excel!.tables['Mentee Info for Matching'];
    if (sheet == null) return [];

    _menteeInfoList.clear();
    
    // Skip header row
    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      if (row.isEmpty || row[0]?.value == null) continue;

      String name = row[0]?.value?.toString() ?? '';
      String email = row[1]?.value?.toString() ?? '';
      String major = row[2]?.value?.toString() ?? '';
      String year = row[3]?.value?.toString() ?? '';
      String careerAspiration = row[4]?.value?.toString() ?? '';
      
      // Parse topics (assuming they're in columns 5+)
      List<String> topics = [];
      for (int j = 5; j < row.length; j++) {
        String? topic = row[j]?.value?.toString();
        if (topic != null && topic.isNotEmpty) {
          topics.add(topic);
        }
      }

      if (name.isNotEmpty) {
        _menteeInfoList.add(MenteeInfo(
          name: name,
          email: email,
          major: major,
          year: year,
          careerAspiration: careerAspiration,
          topics: topics,
        ));
      }
    }

    return _menteeInfoList;
  }

  // Get all assignments
  List<MenteeAssignment> getAllAssignments() => _assignments;

  // Get all mentee info
  List<MenteeInfo> getAllMenteeInfo() => _menteeInfoList;

  // Get all mentors
  List<String> getAllMentors() {
    Set<String> mentors = {};
    for (var assignment in _assignments) {
      if (assignment.mentor != null && assignment.mentor!.isNotEmpty) {
        mentors.add(assignment.mentor!);
      }
    }
    return mentors.toList()..sort();
  }

  // Get all mentees
  List<String> getAllMentees() {
    Set<String> mentees = {};
    for (var assignment in _assignments) {
      mentees.add(assignment.mentee);
    }
    return mentees.toList()..sort();
  }

  // Get acknowledgment status
  Map<String, int> getAcknowledgmentStatus() {
    int signed = 0;
    int unsigned = 0;

    for (var assignment in _assignments) {
      if (assignment.acknowledgmentSigned) {
        signed++;
      } else {
        unsigned++;
      }
    }

    return {
      'Yes': signed,
      'No': unsigned,
      'Unsigned': 0, // For compatibility with Python version
    };
  }

  // Get topic statistics
  Map<String, int> getTopicStatistics() {
    Map<String, int> topicCount = {};
    
    for (var mentee in _menteeInfoList) {
      for (var topic in mentee.topics) {
        topicCount[topic] = (topicCount[topic] ?? 0) + 1;
      }
    }

    // Sort by count descending
    var sortedEntries = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // Search for assignment by mentee name
  MenteeAssignment? getAssignmentByMentee(String menteeName) {
    try {
      return _assignments.firstWhere(
        (assignment) => assignment.mentee.toLowerCase() == menteeName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get assignments by mentor name
  List<MenteeAssignment> getAssignmentsByMentor(String mentorName) {
    return _assignments.where(
      (assignment) => assignment.mentor?.toLowerCase() == mentorName.toLowerCase(),
    ).toList();
  }

  // Search by first name
  List<MenteeAssignment> searchAssignmentsByFirstName(String firstName) {
    String searchTerm = firstName.toLowerCase();
    List<MenteeAssignment> results = [];

    // Search mentees
    for (var assignment in _assignments) {
      String menteeFirstName = assignment.mentee.split(' ')[0].toLowerCase();
      if (menteeFirstName == searchTerm) {
        results.add(assignment);
      }
    }

    return results;
  }

  // Get mentors by first name
  List<String> searchMentorsByFirstName(String firstName) {
    String searchTerm = firstName.toLowerCase();
    Set<String> mentors = {};

    for (var assignment in _assignments) {
      if (assignment.mentor != null) {
        String mentorFirstName = assignment.mentor!.split(' ')[0].toLowerCase();
        if (mentorFirstName == searchTerm) {
          mentors.add(assignment.mentor!);
        }
      }
    }

    return mentors.toList();
  }

  // Get unassigned mentees
  List<String> getUnassignedMentees() {
    List<String> unassigned = [];
    
    for (var assignment in _assignments) {
      if (assignment.mentor == null || assignment.mentor!.isEmpty) {
        unassigned.add(assignment.mentee);
      }
    }
    
    return unassigned;
  }

  // Update assignment
  bool updateAssignment({
    required String menteeName,
    String? mentorName,
    bool? acknowledgmentSigned,
    String? notes,
  }) {
    try {
      var assignmentIndex = _assignments.indexWhere(
        (assignment) => assignment.mentee.toLowerCase() == menteeName.toLowerCase(),
      );
      
      if (assignmentIndex == -1) {
        return false;
      }
      
      // Create updated assignment
      var currentAssignment = _assignments[assignmentIndex];
      _assignments[assignmentIndex] = MenteeAssignment(
        mentee: currentAssignment.mentee,
        mentor: mentorName ?? currentAssignment.mentor,
        acknowledgmentSigned: acknowledgmentSigned ?? currentAssignment.acknowledgmentSigned,
        notes: notes ?? currentAssignment.notes,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get mentee topics by name
  Map<String, List<String>> getMenteeTopics() {
    Map<String, List<String>> topicsByMentee = {};
    
    for (var mentee in _menteeInfoList) {
      topicsByMentee[mentee.name] = mentee.topics;
    }
    
    return topicsByMentee;
  }

  // Get topics for a specific mentee
  List<String>? getTopicsForMentee(String menteeName) {
    try {
      var mentee = _menteeInfoList.firstWhere(
        (m) => m.name.toLowerCase() == menteeName.toLowerCase(),
      );
      return mentee.topics;
    } catch (e) {
      return null;
    }
  }

  // Save Excel file with updates (creates new Excel file with current data)
  Future<Uint8List?> saveToExcel() async {
    try {
      var excel = Excel.createExcel();
      
      // Create Mentee Assignments sheet
      var assignmentsSheet = excel['Mentee Assignments'];
      
      // Add headers
      assignmentsSheet.appendRow([
        TextCellValue('Mentee'),
        TextCellValue('Mentor'), 
        TextCellValue('Acknowledgments signed?'),
        TextCellValue('Notes')
      ]);
      
      // Add data
      for (var assignment in _assignments) {
        assignmentsSheet.appendRow([
          TextCellValue(assignment.mentee),
          TextCellValue(assignment.mentor ?? ''),
          TextCellValue(assignment.acknowledgmentSigned ? 'Yes' : 'No'),
          TextCellValue(assignment.notes ?? '')
        ]);
      }
      
      // Create Mentee Info sheet
      var infoSheet = excel['Mentee Info for Matching'];
      
      // Add headers
      infoSheet.appendRow([
        TextCellValue('First and last name:'),
        TextCellValue('UC Merced Email:'),
        TextCellValue('What is your major(s) and minor? (or undeclared/undecided)'),
        TextCellValue('What year are you in college?'),
        TextCellValue('What is your career aspiration and/or plan for after graduation?'),
        TextCellValue('Which topics would you like to focus on in mentoring? - Selected Choice')
      ]);
      
      // Add data
      for (var mentee in _menteeInfoList) {
        infoSheet.appendRow([
          TextCellValue(mentee.name),
          TextCellValue(mentee.email),
          TextCellValue(mentee.major),
          TextCellValue(mentee.year),
          TextCellValue(mentee.careerAspiration),
          TextCellValue(mentee.topics.join(', '))
        ]);
      }
      
      // Remove default sheet
      excel.delete('Sheet1');
      
      // Encode to bytes
      var fileBytes = excel.encode();
      return fileBytes != null ? Uint8List.fromList(fileBytes) : null;
    } catch (e) {
      print('Error saving Excel: $e');
      return null;
    }
  }
}