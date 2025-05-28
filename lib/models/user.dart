class User {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String? studentId;
  final String? mentor;
  final String? mentee;
  final String acknowledgmentSigned;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.studentId,
    this.mentor,
    this.mentee,
    this.acknowledgmentSigned = 'not_applicable',
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      userType: map['userType'],
      studentId: map['student_id'],
      mentor: map['mentor'],
      mentee: map['mentee'],
      acknowledgmentSigned: map['acknowledgment_signed'] ?? 'not_applicable',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
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
      'mentee': mentee,
      'acknowledgment_signed': acknowledgmentSigned,
      'created_at': createdAt.millisecondsSinceEpoch,
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
    String? acknowledgmentSigned,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      studentId: studentId ?? this.studentId,
      mentor: mentor ?? this.mentor,
      mentee: mentee ?? this.mentee,
      acknowledgmentSigned: acknowledgmentSigned ?? this.acknowledgmentSigned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}