class RegistrationData {
  final String name;
  final String email;
  final String password;
  final String? studentId;
  final String? department;
  final String? role;
  final UserRole userRole;

  RegistrationData({
    required this.name,
    required this.email,
    required this.password,
    this.studentId,
    this.department,
    this.role,
    required this.userRole,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'role': role,
      'userRole': userRole.toString().split('.').last,
    };
  }
}

enum UserRole {
  mentee,
  mentor,
  coordinator,
  developer,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.mentee:
        return 'Mentee';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.coordinator:
        return 'Coordinator';
      case UserRole.developer:
        return 'Developer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.mentee:
        return 'Join as a student seeking guidance';
      case UserRole.mentor:
        return 'Join as someone who provides guidance';
      case UserRole.coordinator:
        return 'Join as a program administrator';
      case UserRole.developer:
        return 'Quick access for development testing';
    }
  }
}