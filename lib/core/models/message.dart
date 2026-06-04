class AppMessage {
  const AppMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  factory AppMessage.fromJson(Map<dynamic, dynamic> json) {
    return AppMessage(
      id: (json['id'] as String?) ?? '',
      senderName: (json['sender_name'] as String?) ?? 'System',
      content: (json['content'] as String?) ?? '',
      sentAt: DateTime.tryParse(
            (json['sent_at'] as String?) ??
                (json['created_at'] as String?) ??
                '',
          ) ??
          DateTime.now(),
      isRead: (json['is_read'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_name': senderName,
        'content': content,
        'sent_at': sentAt.toIso8601String(),
        'created_at': sentAt.toIso8601String(),
        'is_read': isRead,
      };
}
