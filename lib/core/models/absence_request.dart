class AbsenceRequest {
  const AbsenceRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.managerNote = '',
    this.reviewedAt,
  });

  final String id;
  final AbsenceType type;
  final DateTime startDate;
  final DateTime endDate;
  final AbsenceStatus status;
  final DateTime createdAt;
  final String note;
  final String managerNote;
  final DateTime? reviewedAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startDate': _dateOnly(startDate),
      'endDate': _dateOnly(endDate),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'managerNote': managerNote,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  factory AbsenceRequest.fromJson(Map<dynamic, dynamic> json) {
    return AbsenceRequest(
      id: json['id'] as String? ?? '',
      type: AbsenceType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AbsenceType.vacation,
      ),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      status: AbsenceStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AbsenceStatus.pending,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      managerNote: json['managerNote'] as String? ?? '',
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
    );
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

enum AbsenceType { vacation, sick, parental, other }

enum AbsenceStatus { pending, approved, denied }
