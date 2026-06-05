class AppMessage {
  const AppMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.subject = 'Team update',
    this.senderMemberId,
    this.recipientMemberId,
    this.isRead = false,
  });

  final String id;
  final String senderName;
  final String subject;
  final String content;
  final DateTime sentAt;
  final String? senderMemberId;
  final String? recipientMemberId;
  final bool isRead;

  factory AppMessage.fromJson(Map<dynamic, dynamic> json) {
    return AppMessage(
      id: (json['id'] as String?) ?? '',
      senderName: (json['sender_name'] as String?) ?? 'System',
      subject: (json['subject'] as String?) ?? 'Team update',
      content: (json['content'] as String?) ?? '',
      sentAt: DateTime.tryParse(
            (json['sent_at'] as String?) ??
                (json['created_at'] as String?) ??
                '',
          ) ??
          DateTime.now(),
      senderMemberId: json['sender_member_id'] as String?,
      recipientMemberId: json['recipient_member_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_name': senderName,
        'subject': subject,
        'content': content,
        'sent_at': sentAt.toIso8601String(),
        'created_at': sentAt.toIso8601String(),
        'sender_member_id': senderMemberId,
        'recipient_member_id': recipientMemberId,
        'is_read': isRead,
      };
}
