class AcknowledgmentData {
  final String fullName;
  final DateTime date;
  final bool isAcknowledged;
  final String? menteeId;
  final String? email;

  AcknowledgmentData({
    required this.fullName,
    required this.date,
    required this.isAcknowledged,
    this.menteeId,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'date': date.toIso8601String(),
      'isAcknowledged': isAcknowledged,
      'menteeId': menteeId,
      'email': email,
      'acknowledgedAt': DateTime.now().toIso8601String(),
    };
  }

  factory AcknowledgmentData.fromJson(Map<String, dynamic> json) {
    return AcknowledgmentData(
      fullName: json['fullName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isAcknowledged: json['isAcknowledged'] ?? false,
      menteeId: json['menteeId'],
      email: json['email'],
    );
  }
}