class User {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String? studentId;
  final String? mentor;
  final String? mentee;
  final List<String>? mentees; // For mentors with multiple mentees
  final String acknowledgmentSigned;
  final String? department; // Added 5/29/25
  final String? yearMajor; // Added 5/29/25
  final String? careerAspiration; // Added for Excel import
  final List<String>? topics; // Added for Excel import  
  final String? importSource; // Added for Excel import tracking
  final String? importBatchId; // Added for Excel import tracking
  final DateTime createdAt;
  final String? firebaseUid; // Firebase Auth UID
  final bool emailVerified; // Firebase Auth email verification status
  final DateTime? accountCreatedAt; // Firebase Auth account creation timestamp

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.studentId,
    this.mentor,
    this.mentee,
    this.mentees,
    this.acknowledgmentSigned = 'not_applicable',
    this.department,
    this.yearMajor,
    this.careerAspiration,
    this.topics,
    this.importSource,
    this.importBatchId,
    required this.createdAt,
    this.firebaseUid,
    this.emailVerified = false,
    this.accountCreatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      userType: map['userType'],
      studentId: map['student_id'],
      mentor: map['mentor'],
      mentee: map['mentee'] is String ? map['mentee'] : null,
      mentees: map['mentee'] is List ? List<String>.from(map['mentee']) : null,
      acknowledgmentSigned: map['acknowledgment_signed'] ?? 'not_applicable',
      department: map['department'],
      yearMajor: map['year_major'],
      careerAspiration: map['career_aspiration'],
      topics: map['topics'] != null ? List<String>.from(map['topics']) : null,
      importSource: map['import_source'],
      importBatchId: map['import_batch_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      firebaseUid: map['firebase_uid'],
      emailVerified: map['email_verified'] ?? false,
      accountCreatedAt: map['account_created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['account_created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'student_id': studentId,
      'mentor': mentor,
      'mentee': mentees ?? mentee,
      'acknowledgment_signed': acknowledgmentSigned,
      'department': department,
      'year_major': yearMajor,
      'career_aspiration': careerAspiration,
      'topics': topics,
      'import_source': importSource,
      'import_batch_id': importBatchId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'firebase_uid': firebaseUid,
      'email_verified': emailVerified,
      'account_created_at': accountCreatedAt?.millisecondsSinceEpoch,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? userType,
    String? studentId,
    String? mentor,
    String? mentee,
    List<String>? mentees,
    String? acknowledgmentSigned,
    String? department,
    String? yearMajor,
    String? careerAspiration,
    List<String>? topics,
    String? importSource,
    String? importBatchId,
    DateTime? createdAt,
    String? firebaseUid,
    bool? emailVerified,
    DateTime? accountCreatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      studentId: studentId ?? this.studentId,
      mentor: mentor ?? this.mentor,
      mentee: mentee ?? this.mentee,
      mentees: mentees ?? this.mentees,
      acknowledgmentSigned: acknowledgmentSigned ?? this.acknowledgmentSigned,
      department: department ?? this.department,
      yearMajor: yearMajor ?? this.yearMajor,
      careerAspiration: careerAspiration ?? this.careerAspiration,
      topics: topics ?? this.topics,
      importSource: importSource ?? this.importSource,
      importBatchId: importBatchId ?? this.importBatchId,
      createdAt: createdAt ?? this.createdAt,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      emailVerified: emailVerified ?? this.emailVerified,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
    );
  }
}