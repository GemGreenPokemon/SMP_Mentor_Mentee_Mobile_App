/// Events that can occur related to tab visibility
enum VisibilityEventType {
  tabBecameVisible,
  tabBecameHidden,
  tabBecameLeader,
  tabLostLeadership,
  tabClosed,
  dataUpdated,
}

class VisibilityEvent {
  final VisibilityEventType type;
  final String tabId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  VisibilityEvent({
    required this.type,
    required this.tabId,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'tabId': tabId,
      'timestamp': timestamp.toIso8601String(),
      if (data != null) 'data': data,
    };
  }

  factory VisibilityEvent.fromJson(Map<String, dynamic> json) {
    return VisibilityEvent(
      type: VisibilityEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      tabId: json['tabId'],
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
    );
  }
}