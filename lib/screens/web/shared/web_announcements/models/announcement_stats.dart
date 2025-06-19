class AnnouncementStats {
  final int total;
  final int high;
  final int medium;
  final int low;
  final int general;

  AnnouncementStats({
    required this.total,
    required this.high,
    required this.medium,
    required this.low,
    required this.general,
  });

  factory AnnouncementStats.fromMap(Map<String, int> map) {
    return AnnouncementStats(
      total: map['total'] ?? 0,
      high: map['high'] ?? 0,
      medium: map['medium'] ?? 0,
      low: map['low'] ?? 0,
      general: map['general'] ?? 0,
    );
  }
}