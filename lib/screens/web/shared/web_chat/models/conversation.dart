class Conversation {
  final String id;
  final String name;
  final String role;
  final String lastMessage;
  final String lastMessageTime;
  final bool isActive;
  final bool hasUnread;
  final int unreadCount;
  final String? avatarUrl;
  final DateTime lastUpdated;
  
  Conversation({
    required this.id,
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isActive = false,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.avatarUrl,
    required this.lastUpdated,
  });
  
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';
  
  Conversation copyWith({
    String? id,
    String? name,
    String? role,
    String? lastMessage,
    String? lastMessageTime,
    bool? isActive,
    bool? hasUnread,
    int? unreadCount,
    String? avatarUrl,
    DateTime? lastUpdated,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isActive: isActive ?? this.isActive,
      hasUnread: hasUnread ?? this.hasUnread,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'isActive': isActive,
      'hasUnread': hasUnread,
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] ?? '',
      isActive: map['isActive'] ?? false,
      hasUnread: map['hasUnread'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
      avatarUrl: map['avatarUrl'],
      lastUpdated: DateTime.tryParse(map['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }
}