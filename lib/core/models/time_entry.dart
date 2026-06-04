class TimeEntry {
  const TimeEntry({
    required this.id,
    this.shiftId,
    required this.clockInAt,
    this.clockOutAt,
    this.breakMinutes = 0,
    this.workedMinutes = 0,
    this.notes = '',
    this.status = TimeEntryStatus.open,
  });

  final String id;
  final String? shiftId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int breakMinutes;
  final int workedMinutes;
  final String notes;
  final TimeEntryStatus status;

  bool get isOpen => clockOutAt == null;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'clockInAt': clockInAt.toIso8601String(),
      'clockOutAt': clockOutAt?.toIso8601String(),
      'breakMinutes': breakMinutes,
      'workedMinutes': workedMinutes,
      'notes': notes,
      'status': status.name,
    };
  }

  factory TimeEntry.fromJson(Map<dynamic, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String? ?? '',
      shiftId: json['shiftId'] as String?,
      clockInAt: DateTime.tryParse(json['clockInAt'] as String? ?? '') ??
          DateTime.now(),
      clockOutAt: DateTime.tryParse(json['clockOutAt'] as String? ?? ''),
      breakMinutes: json['breakMinutes'] as int? ?? 0,
      workedMinutes: json['workedMinutes'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      status: TimeEntryStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TimeEntryStatus.open,
      ),
    );
  }
}

enum TimeEntryStatus { open, submitted, approved }
