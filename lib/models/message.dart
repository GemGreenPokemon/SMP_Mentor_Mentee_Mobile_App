import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Handle sent_at which can be either Timestamp or int
    DateTime sentAtDateTime;
    if (map['sent_at'] is Timestamp) {
      sentAtDateTime = (map['sent_at'] as Timestamp).toDate();
    } else if (map['sent_at'] is int) {
      sentAtDateTime = DateTime.fromMillisecondsSinceEpoch(map['sent_at']);
    } else {
      sentAtDateTime = DateTime.now(); // Fallback
    }
    
    return Message(
      id: map['id'] ?? '',
      chatId: map['chat_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      message: map['message'] ?? '',
      sentAt: sentAtDateTime,
      synced: map['synced'] ?? true,
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