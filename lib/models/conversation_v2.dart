import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation model for the new conversation-centric structure
class ConversationV2 {
  final String id; // Conversation ID (user1__user2 format)
  final List<String> participants;
  final Map<String, ParticipantDetails> participantDetails;
  final LastMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String type; // 'direct' or 'group'
  final Map<String, dynamic> metadata;
  final Map<String, UserSettings> userSettings;

  ConversationV2({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.type = 'direct',
    this.metadata = const {},
    required this.userSettings,
  });

  factory ConversationV2.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse participant details
    final participantDetailsMap = <String, ParticipantDetails>{};
    final detailsData = data['participant_details'] as Map<String, dynamic>? ?? {};
    detailsData.forEach((key, value) {
      participantDetailsMap[key] = ParticipantDetails.fromMap(value as Map<String, dynamic>);
    });
    
    // Parse user settings
    final userSettingsMap = <String, UserSettings>{};
    final settingsData = data['user_settings'] as Map<String, dynamic>? ?? {};
    settingsData.forEach((key, value) {
      userSettingsMap[key] = UserSettings.fromMap(value as Map<String, dynamic>);
    });
    
    return ConversationV2(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails: participantDetailsMap,
      lastMessage: data['last_message'] != null 
          ? LastMessage.fromMap(data['last_message'] as Map<String, dynamic>)
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      type: data['type'] ?? 'direct',
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      userSettings: userSettingsMap,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participant_details': participantDetails.map((key, value) => MapEntry(key, value.toMap())),
      'last_message': lastMessage?.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'type': type,
      'metadata': metadata,
      'user_settings': userSettings.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Get the other participant's ID (for direct conversations)
  String? getOtherParticipantId(String currentUserId) {
    if (type != 'direct' || participants.length != 2) return null;
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  /// Get user settings for a specific user
  UserSettings? getUserSettings(String userId) {
    return userSettings[userId];
  }

  /// Check if user has unread messages
  bool hasUnreadMessages(String userId) {
    return (getUserSettings(userId)?.unreadCount ?? 0) > 0;
  }

  /// Check if conversation is archived for user
  bool isArchivedForUser(String userId) {
    return getUserSettings(userId)?.archived ?? false;
  }

  /// Check if conversation is pinned for user
  bool isPinnedForUser(String userId) {
    return getUserSettings(userId)?.pinned ?? false;
  }

  /// Check if notifications are enabled for user
  bool areNotificationsEnabledForUser(String userId) {
    return getUserSettings(userId)?.notificationsEnabled ?? true;
  }
}

class ParticipantDetails {
  final String name;
  final String userType;
  final DateTime joinedAt;

  ParticipantDetails({
    required this.name,
    required this.userType,
    required this.joinedAt,
  });

  factory ParticipantDetails.fromMap(Map<String, dynamic> map) {
    return ParticipantDetails(
      name: map['name'] ?? '',
      userType: map['userType'] ?? '',
      joinedAt: (map['joined_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userType': userType,
      'joined_at': Timestamp.fromDate(joinedAt),
    };
  }
}

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] ?? '',
      senderId: map['sender_id'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender_id': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class UserSettings {
  final DateTime lastRead;
  final int unreadCount;
  final bool notificationsEnabled;
  final bool archived;
  final bool pinned;
  final String? customNickname;

  UserSettings({
    required this.lastRead,
    this.unreadCount = 0,
    this.notificationsEnabled = true,
    this.archived = false,
    this.pinned = false,
    this.customNickname,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      lastRead: (map['last_read'] as Timestamp).toDate(),
      unreadCount: map['unread_count'] ?? 0,
      notificationsEnabled: map['notifications_enabled'] ?? true,
      archived: map['archived'] ?? false,
      pinned: map['pinned'] ?? false,
      customNickname: map['custom_nickname'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'last_read': Timestamp.fromDate(lastRead),
      'unread_count': unreadCount,
      'notifications_enabled': notificationsEnabled,
      'archived': archived,
      'pinned': pinned,
      'custom_nickname': customNickname,
    };
  }
}