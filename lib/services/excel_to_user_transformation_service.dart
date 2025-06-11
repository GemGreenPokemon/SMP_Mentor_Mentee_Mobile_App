import 'dart:math';
import 'dart:convert';
import '../models/user.dart';
import 'excel_parser_service.dart';

class ExcelToUserTransformationService {
  static final ExcelToUserTransformationService _instance = ExcelToUserTransformationService._internal();
  factory ExcelToUserTransformationService() => _instance;
  ExcelToUserTransformationService._internal();

  /// Transform Excel data to User model format for bulk import
  TransformationResult transformToUsers(
    List<MenteeAssignment> assignments,
    List<MenteeInfo> menteeInfo, {
    String importBatchId = '',
  }) {
    final transformationResult = TransformationResult();
    
    // Generate batch ID if not provided
    if (importBatchId.isEmpty) {
      importBatchId = 'excel_import_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Create a map of name to MenteeInfo for efficient lookup
    final Map<String, MenteeInfo> menteeInfoMap = {};
    for (var info in menteeInfo) {
      menteeInfoMap[info.name.toLowerCase().trim()] = info;
    }

    // Track all unique mentor names to create mentor accounts
    final Set<String> mentorNames = {};
    final Set<String> processedMenteeNames = {};

    // First pass: Collect unique mentors and mentees
    for (var assignment in assignments) {
      if (assignment.mentor != null && assignment.mentor!.isNotEmpty) {
        mentorNames.add(assignment.mentor!.trim());
      }
      processedMenteeNames.add(assignment.mentee.toLowerCase().trim());
    }

    // Transform mentors
    for (var mentorName in mentorNames) {
      try {
        final mentorUser = _createMentorUser(
          mentorName, 
          importBatchId,
          assignments.where((a) => a.mentor == mentorName).toList()
        );
        transformationResult.users.add(mentorUser);
        transformationResult.mentorMap[mentorName] = mentorUser;
      } catch (e) {
        transformationResult.errors.add(TransformationError(
          type: 'mentor_creation',
          message: 'Failed to create mentor: $mentorName - ${e.toString()}',
          data: {'mentorName': mentorName}
        ));
      }
    }

    // Transform mentees
    for (var assignment in assignments) {
      try {
        final menteeKey = assignment.mentee.toLowerCase().trim();
        final menteeInfoData = menteeInfoMap[menteeKey];
        
        final menteeUser = _createMenteeUser(
          assignment, 
          menteeInfoData, 
          importBatchId
        );
        
        transformationResult.users.add(menteeUser);
        transformationResult.menteeMap[assignment.mentee] = menteeUser;

        // Track mentor-mentee relationship for later processing
        if (assignment.mentor != null && assignment.mentor!.isNotEmpty) {
          transformationResult.mentorships.add(MentorshipMapping(
            mentorName: assignment.mentor!,
            menteeName: assignment.mentee,
            notes: assignment.notes
          ));
        }

      } catch (e) {
        transformationResult.errors.add(TransformationError(
          type: 'mentee_creation',
          message: 'Failed to create mentee: ${assignment.mentee} - ${e.toString()}',
          data: {'menteeName': assignment.mentee}
        ));
      }
    }

    // Second pass: Create missing mentors that appear in mentorships but weren't created as standalone mentors
    final missingMentors = <String>{};
    for (var mentorship in transformationResult.mentorships) {
      if (!transformationResult.mentorMap.containsKey(mentorship.mentorName)) {
        missingMentors.add(mentorship.mentorName);
      }
    }

    for (var mentorName in missingMentors) {
      try {
        print('🔄 Creating on-demand mentor: $mentorName');
        final mentorUser = _createMentorUser(
          mentorName, 
          importBatchId,
          assignments.where((a) => a.mentor?.trim().toLowerCase() == mentorName.trim().toLowerCase()).toList()
        );
        transformationResult.users.add(mentorUser);
        transformationResult.mentorMap[mentorName] = mentorUser;
        
        transformationResult.warnings.add(TransformationWarning(
          type: 'mentor_created_on_demand',
          message: 'Created mentor user on-demand: $mentorName',
          data: {'mentorName': mentorName}
        ));
      } catch (e) {
        transformationResult.warnings.add(TransformationWarning(
          type: 'mentor_creation_failed',
          message: 'Failed to create on-demand mentor: $mentorName - ${e.toString()}',
          data: {'mentorName': mentorName}
        ));
      }
    }

    // Validate the transformation result
    _validateTransformationResult(transformationResult);

    return transformationResult;
  }

  /// Create a mentor user from name and assignments
  Map<String, dynamic> _createMentorUser(
    String mentorName, 
    String importBatchId,
    List<MenteeAssignment> menteeAssignments
  ) {
    // Generate a plausible email for the mentor (will need to be updated manually)
    final email = _generatePlaceholderEmail(mentorName, 'mentor');
    
    // Extract mentee names from assignments
    final assignedMentees = menteeAssignments.map((a) => a.mentee.trim()).toList();
    
    final userData = {
      'name': mentorName.trim(),
      'email': email,
      'userType': 'mentor',
      'acknowledgment_signed': 'not_applicable',
      'import_source': 'excel',
      'import_batch_id': importBatchId,
      'student_id': _generatePlaceholderStudentId('M'),
      'department': 'TBD', // To be determined manually
      'year_major': 'Graduate/Alumni', // Default assumption for mentors
    };

    // Add mentee relationships if available
    if (assignedMentees.isNotEmpty) {
      // Convert to JSON string as expected by database schema
      userData['mentee'] = jsonEncode(assignedMentees);
    }
    
    return userData;
  }

  /// Create a mentee user from assignment and info data
  Map<String, dynamic> _createMenteeUser(
    MenteeAssignment assignment, 
    MenteeInfo? menteeInfo, 
    String importBatchId
  ) {
    // Use menteeInfo email if available, otherwise generate placeholder
    final email = menteeInfo?.email.isNotEmpty == true 
        ? menteeInfo!.email.toLowerCase().trim()
        : _generatePlaceholderEmail(assignment.mentee, 'mentee');

    final userData = {
      'name': assignment.mentee.trim(),
      'email': email,
      'userType': 'mentee',
      'acknowledgment_signed': assignment.acknowledgmentSigned ? 'yes' : 'no',
      'import_source': 'excel',
      'import_batch_id': importBatchId,
    };

    // Add mentor relationship if available
    if (assignment.mentor != null && assignment.mentor!.isNotEmpty) {
      userData['mentor'] = assignment.mentor!.trim();
    }

    // Add menteeInfo data if available - now properly mapped from corrected parser
    if (menteeInfo != null) {
      // department field gets the major
      if (menteeInfo.major.isNotEmpty) {
        userData['department'] = menteeInfo.major.trim();
      }
      
      // year_major field combines year and major for display
      if (menteeInfo.year.isNotEmpty && menteeInfo.major.isNotEmpty) {
        userData['year_major'] = '${menteeInfo.year.trim()}, ${menteeInfo.major.trim()}';
      } else if (menteeInfo.year.isNotEmpty) {
        userData['year_major'] = menteeInfo.year.trim();
      } else if (menteeInfo.major.isNotEmpty) {
        userData['year_major'] = menteeInfo.major.trim();
      }
      
      // Skip career_aspiration and topics as they're not in the database schema
      // These fields can be added later when the schema is updated
    }

    // Generate placeholder student ID if not available
    userData['student_id'] = _generatePlaceholderStudentId('E');

    return userData;
  }

  /// Generate a placeholder email based on name and role
  String _generatePlaceholderEmail(String name, String role) {
    final cleanName = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(' ', '.');
    return '$cleanName.$role@placeholder.edu';
  }

  /// Generate a placeholder student ID
  String _generatePlaceholderStudentId(String prefix) {
    final random = Random();
    final number = random.nextInt(99999).toString().padLeft(5, '0');
    return '$prefix$number';
  }

  /// Validate the transformation result for common issues
  void _validateTransformationResult(TransformationResult result) {
    final emailSet = <String>{};
    final nameSet = <String>{};

    for (var user in result.users) {
      final email = user['email'] as String;
      final name = user['name'] as String;

      // Check for duplicate emails
      if (emailSet.contains(email)) {
        result.warnings.add(TransformationWarning(
          type: 'duplicate_email',
          message: 'Duplicate email detected: $email',
          data: {'email': email}
        ));
      }
      emailSet.add(email);

      // Check for duplicate names
      if (nameSet.contains(name.toLowerCase())) {
        result.warnings.add(TransformationWarning(
          type: 'duplicate_name',
          message: 'Duplicate name detected: $name',
          data: {'name': name}
        ));
      }
      nameSet.add(name.toLowerCase());

      // Validate required fields
      if (name.isEmpty || email.isEmpty) {
        result.errors.add(TransformationError(
          type: 'missing_required_field',
          message: 'Missing required field for user: $name',
          data: {'user': user}
        ));
      }

      // Check for placeholder emails that need updating
      if (email.contains('@placeholder.edu')) {
        result.warnings.add(TransformationWarning(
          type: 'placeholder_email',
          message: 'Placeholder email needs manual update: $email',
          data: {'name': name, 'email': email}
        ));
      }
    }

    // Validate and filter mentorships
    for (var mentorship in result.mentorships) {
      bool isValid = true;
      
      // Check if mentor exists
      if (!result.mentorMap.containsKey(mentorship.mentorName)) {
        result.warnings.add(TransformationWarning(
          type: 'mentor_not_found',
          message: 'Mentor not found, skipping mentorship: ${mentorship.mentorName} -> ${mentorship.menteeName}',
          data: {'mentorship': mentorship.toMap()}
        ));
        isValid = false;
      }
      
      // Check if mentee exists
      if (!result.menteeMap.containsKey(mentorship.menteeName)) {
        result.errors.add(TransformationError(
          type: 'mentee_not_found', 
          message: 'Mentee not found for mentorship: ${mentorship.menteeName}',
          data: {'mentorship': mentorship.toMap()},
          isCritical: true
        ));
        isValid = false;
      }
      
      // Add to appropriate list
      if (isValid) {
        result.validMentorships.add(mentorship);
      } else {
        result.skippedMentorships.add(mentorship);
      }
    }
  }

  /// Get statistics about the transformation
  TransformationStats getTransformationStats(TransformationResult result) {
    return TransformationStats(
      totalUsers: result.users.length,
      mentors: result.users.where((u) => u['userType'] == 'mentor').length,
      mentees: result.users.where((u) => u['userType'] == 'mentee').length,
      mentorships: result.mentorships.length,
      successfulMentorships: result.validMentorships.length,
      skippedMentorships: result.skippedMentorships.length,
      errors: result.errors.length,
      warnings: result.warnings.length,
      usersWithEmail: result.users.where((u) => !(u['email'] as String).contains('@placeholder.edu')).length,
      usersWithPlaceholderEmail: result.users.where((u) => (u['email'] as String).contains('@placeholder.edu')).length,
    );
  }
}

/// Result of Excel to User transformation
class TransformationResult {
  final List<Map<String, dynamic>> users = [];
  final List<MentorshipMapping> mentorships = [];
  final List<MentorshipMapping> validMentorships = [];
  final List<MentorshipMapping> skippedMentorships = [];
  final List<TransformationError> errors = [];
  final List<TransformationWarning> warnings = [];
  final Map<String, Map<String, dynamic>> mentorMap = {};
  final Map<String, Map<String, dynamic>> menteeMap = {};

  bool get hasErrors => errors.isNotEmpty;
  bool get hasCriticalErrors => errors.where((e) => e.isCritical).isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => errors.isEmpty;
  bool get canProceedWithImport => !hasCriticalErrors;
}

/// Represents a mentor-mentee relationship to be created
class MentorshipMapping {
  final String mentorName;
  final String menteeName;
  final String? notes;

  MentorshipMapping({
    required this.mentorName,
    required this.menteeName,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'mentorName': mentorName,
    'menteeName': menteeName,
    if (notes != null) 'notes': notes,
  };
}

/// Transformation error
class TransformationError {
  final String type;
  final String message;
  final Map<String, dynamic>? data;
  final bool isCritical;

  TransformationError({
    required this.type,
    required this.message,
    this.data,
    this.isCritical = true,
  });

  @override
  String toString() => '$type: $message';
}

/// Transformation warning
class TransformationWarning {
  final String type;
  final String message;
  final Map<String, dynamic>? data;

  TransformationWarning({
    required this.type,
    required this.message,
    this.data,
  });

  @override
  String toString() => '$type: $message';
}

/// Statistics about the transformation
class TransformationStats {
  final int totalUsers;
  final int mentors;
  final int mentees;
  final int mentorships;
  final int successfulMentorships;
  final int skippedMentorships;
  final int errors;
  final int warnings;
  final int usersWithEmail;
  final int usersWithPlaceholderEmail;

  TransformationStats({
    required this.totalUsers,
    required this.mentors,
    required this.mentees,
    required this.mentorships,
    required this.successfulMentorships,
    required this.skippedMentorships,
    required this.errors,
    required this.warnings,
    required this.usersWithEmail,
    required this.usersWithPlaceholderEmail,
  });

  @override
  String toString() {
    return '''
Transformation Statistics:
- Total Users: $totalUsers
- Mentors: $mentors  
- Mentees: $mentees
- Total Mentorships: $mentorships
- Successful Mentorships: $successfulMentorships
- Skipped Mentorships: $skippedMentorships
- Errors: $errors
- Warnings: $warnings
- Users with real emails: $usersWithEmail
- Users with placeholder emails: $usersWithPlaceholderEmail
''';
  }
}