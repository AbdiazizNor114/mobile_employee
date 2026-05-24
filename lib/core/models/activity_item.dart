class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.createdAt,
    required this.type,
    this.isUnread = false,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime createdAt;
  final ActivityType type;
  final bool isUnread;

  ActivityItem copyWith({
    String? id,
    String? title,
    String? detail,
    DateTime? createdAt,
    ActivityType? type,
    bool? isUnread,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'detail': detail,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isUnread': isUnread,
    };
  }

  factory ActivityItem.fromJson(Map<dynamic, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: ActivityType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ActivityType.system,
      ),
      isUnread: json['isUnread'] as bool? ?? false,
    );
  }
}

enum ActivityType { shift, deduction, swap, system }
