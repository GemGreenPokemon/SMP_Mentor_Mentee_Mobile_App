import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/excel_parser_service.dart';

class ImportPreviewData {
  final List<User> usersToImport;
  final List<MenteeAssignment> menteeAssignments;
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final int totalUsers;
  final int mentorsCount;
  final int menteesCount;
  final int existingUsersCount;

  ImportPreviewData({
    required this.usersToImport,
    required this.menteeAssignments,
    required this.errors,
    required this.warnings,
    required this.totalUsers,
    required this.mentorsCount,
    required this.menteesCount,
    required this.existingUsersCount,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get canImport => !hasErrors && usersToImport.isNotEmpty;

  factory ImportPreviewData.empty() {
    return ImportPreviewData(
      usersToImport: [],
      menteeAssignments: [],
      errors: {},
      warnings: {},
      totalUsers: 0,
      mentorsCount: 0,
      menteesCount: 0,
      existingUsersCount: 0,
    );
  }
}