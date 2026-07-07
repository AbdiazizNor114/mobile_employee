class AppMessage {
  const AppMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.subject = '',
    this.senderMemberId,
    this.recipientMemberId,
    this.senderProfilePhotoUrl = '',
    this.isRead = false,
    this.reactionCounts = const {},
    this.myReaction,
  });

  final String id;
  final String senderName;
  final String subject;
  final String content;
  final DateTime sentAt;
  final String? senderMemberId;
  final String? recipientMemberId;
  final String senderProfilePhotoUrl;
  final bool isRead;
  final Map<String, int> reactionCounts;
  final String? myReaction;

  factory AppMessage.fromJson(Map<dynamic, dynamic> json) {
    return AppMessage(
      id: (json['id'] as String?) ?? '',
      senderName: (json['sender_name'] as String?) ?? 'System',
      subject: (json['subject'] as String?)?.trim() ?? '',
      content: (json['content'] as String?) ?? '',
      sentAt: DateTime.tryParse(
            (json['sent_at'] as String?) ??
                (json['created_at'] as String?) ??
                '',
          ) ??
          DateTime.now(),
      senderMemberId: json['sender_member_id'] as String?,
      recipientMemberId: json['recipient_member_id'] as String?,
      senderProfilePhotoUrl: (json['sender_profile_photo_url'] as String?) ??
          (json['senderProfilePhotoUrl'] as String?) ??
          (json['sender_photo_url'] as String?) ??
          (json['profile_photo_url'] as String?) ??
          '',
      isRead: (json['is_read'] as bool?) ?? false,
      reactionCounts: _parseReactionCounts(
          json['reaction_counts'] ?? json['reactionCounts']),
      myReaction:
          (json['my_reaction'] as String?) ?? (json['myReaction'] as String?),
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
        'sender_profile_photo_url': senderProfilePhotoUrl,
        'is_read': isRead,
        'reaction_counts': reactionCounts,
        'my_reaction': myReaction,
      };
}

Map<String, int> _parseReactionCounts(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, count) => MapEntry(
      '$key',
      count is int ? count : int.tryParse('$count') ?? 0,
    ),
  );
}
