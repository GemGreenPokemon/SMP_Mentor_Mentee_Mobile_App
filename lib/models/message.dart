class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool synced;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    this.synced = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      message: map['message'],
      sentAt: DateTime.fromMillisecondsSinceEpoch(map['sent_at']),
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'sent_at': sentAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }
}