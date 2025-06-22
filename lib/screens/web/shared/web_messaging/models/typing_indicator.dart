class TypingIndicator {
  final String conversationId;
  final List<String> userIds;
  final List<String> userNames;
  final DateTime timestamp;

  TypingIndicator({
    required this.conversationId,
    required this.userIds,
    required this.userNames,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get displayText {
    if (userNames.isEmpty) return '';
    
    if (userNames.length == 1) {
      return '${userNames.first} is typing...';
    } else if (userNames.length == 2) {
      return '${userNames.join(' and ')} are typing...';
    } else {
      final displayNames = userNames.take(2).join(', ');
      final othersCount = userNames.length - 2;
      return '$displayNames and $othersCount other${othersCount > 1 ? 's' : ''} are typing...';
    }
  }

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 5;
  }
}