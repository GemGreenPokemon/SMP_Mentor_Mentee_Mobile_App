class ChatMessage {
  final String id;
  final String sender;
  final String message;
  final String time;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  
  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    required this.isMe,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'time': time,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'type': type.toString(),
    };
  }
  
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      time: map['time'] ?? '',
      isMe: map['isMe'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum MessageType {
  text,
  image,
  file,
  voice,
  video,
}