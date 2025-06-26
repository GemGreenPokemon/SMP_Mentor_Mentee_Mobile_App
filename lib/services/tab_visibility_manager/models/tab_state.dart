/// Tab state model for tracking tab visibility and leadership
class TabState {
  final String tabId;
  final bool isVisible;
  final bool isLeader;
  final DateTime lastActivity;
  final DateTime createdAt;

  TabState({
    required this.tabId,
    required this.isVisible,
    required this.isLeader,
    required this.lastActivity,
    required this.createdAt,
  });

  TabState copyWith({
    bool? isVisible,
    bool? isLeader,
    DateTime? lastActivity,
  }) {
    return TabState(
      tabId: tabId,
      isVisible: isVisible ?? this.isVisible,
      isLeader: isLeader ?? this.isLeader,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tabId': tabId,
      'isVisible': isVisible,
      'isLeader': isLeader,
      'lastActivity': lastActivity.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TabState.fromJson(Map<String, dynamic> json) {
    return TabState(
      tabId: json['tabId'] ?? '',
      isVisible: json['isVisible'] ?? true,
      isLeader: json['isLeader'] ?? false,
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity']) 
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}