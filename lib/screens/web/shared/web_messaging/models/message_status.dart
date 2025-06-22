enum MessageStatusType {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageStatus {
  final String messageId;
  final MessageStatusType status;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? error;

  MessageStatus({
    required this.messageId,
    required this.status,
    this.readAt,
    this.deliveredAt,
    this.error,
  });

  factory MessageStatus.sending(String messageId) {
    return MessageStatus(
      messageId: messageId,
      status: MessageStatusType.sending,
    );
  }

  factory MessageStatus.sent(String messageId) {
    return MessageStatus(
      messageId: messageId,
      status: MessageStatusType.sent,
    );
  }

  factory MessageStatus.delivered(String messageId, DateTime deliveredAt) {
    return MessageStatus(
      messageId: messageId,
      status: MessageStatusType.delivered,
      deliveredAt: deliveredAt,
    );
  }

  factory MessageStatus.read(String messageId, DateTime readAt) {
    return MessageStatus(
      messageId: messageId,
      status: MessageStatusType.read,
      readAt: readAt,
    );
  }

  factory MessageStatus.failed(String messageId, String error) {
    return MessageStatus(
      messageId: messageId,
      status: MessageStatusType.failed,
      error: error,
    );
  }

  MessageStatus copyWith({
    MessageStatusType? status,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? error,
  }) {
    return MessageStatus(
      messageId: messageId,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      error: error ?? this.error,
    );
  }
}