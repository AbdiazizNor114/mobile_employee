class Shift {
  const Shift({
    required this.id,
    required this.role,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    this.breakMinutes = 0,
    required this.status,
    this.notes = '',
    this.workConfirmationRequired = false,
    this.workConfirmationStatus = WorkConfirmationStatus.pending,
    this.workConfirmationSource,
    this.workConfirmationReason,
    this.workConfirmedAt,
    this.workConfirmedByMemberId,
  });

  final String id;
  final String role;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final ShiftStatus status;
  final String notes;
  final bool workConfirmationRequired;
  final WorkConfirmationStatus workConfirmationStatus;
  final String? workConfirmationSource;
  final String? workConfirmationReason;
  final DateTime? workConfirmedAt;
  final String? workConfirmedByMemberId;

  Shift copyWith({
    String? id,
    String? role,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    int? breakMinutes,
    ShiftStatus? status,
    String? notes,
    bool? workConfirmationRequired,
    WorkConfirmationStatus? workConfirmationStatus,
    String? workConfirmationSource,
    String? workConfirmationReason,
    DateTime? workConfirmedAt,
    String? workConfirmedByMemberId,
  }) {
    return Shift(
      id: id ?? this.id,
      role: role ?? this.role,
      location: location ?? this.location,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      workConfirmationRequired:
          workConfirmationRequired ?? this.workConfirmationRequired,
      workConfirmationStatus:
          workConfirmationStatus ?? this.workConfirmationStatus,
      workConfirmationSource:
          workConfirmationSource ?? this.workConfirmationSource,
      workConfirmationReason:
          workConfirmationReason ?? this.workConfirmationReason,
      workConfirmedAt: workConfirmedAt ?? this.workConfirmedAt,
      workConfirmedByMemberId:
          workConfirmedByMemberId ?? this.workConfirmedByMemberId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'role': role,
      'location': location,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'breakMinutes': breakMinutes,
      'status': status.name,
      'notes': notes,
      'workConfirmationRequired': workConfirmationRequired,
      'workConfirmationStatus': workConfirmationStatus.name,
      'workConfirmationSource': workConfirmationSource,
      'workConfirmationReason': workConfirmationReason,
      'workConfirmedAt': workConfirmedAt?.toIso8601String(),
      'workConfirmedByMemberId': workConfirmedByMemberId,
    };
  }

  bool hasEnded([DateTime? at]) {
    return !endsAt.isAfter(at ?? DateTime.now());
  }

  bool canBeAccepted([DateTime? at]) {
    return status == ShiftStatus.available && !hasEnded(at);
  }

  DateTime get workConfirmationDeadline => endsAt.add(const Duration(days: 7));

  bool get isWorkConfirmed =>
      workConfirmationStatus == WorkConfirmationStatus.confirmed;

  bool isAwaitingWorkConfirmation([DateTime? at]) {
    return workConfirmationRequired &&
        status != ShiftStatus.available &&
        hasEnded(at) &&
        workConfirmationStatus == WorkConfirmationStatus.pending;
  }

  bool canConfirmWork([DateTime? at]) {
    final reference = at ?? DateTime.now();
    return isAwaitingWorkConfirmation(reference) &&
        !reference.isAfter(workConfirmationDeadline);
  }

  bool isWorkConfirmationOverdue([DateTime? at]) {
    final reference = at ?? DateTime.now();
    return isAwaitingWorkConfirmation(reference) &&
        reference.isAfter(workConfirmationDeadline);
  }

  factory Shift.fromJson(Map<dynamic, dynamic> json) {
    return Shift(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(json['endsAt'] as String? ?? '') ?? DateTime.now(),
      breakMinutes: json['breakMinutes'] as int? ?? 0,
      status: ShiftStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ShiftStatus.confirmed,
      ),
      notes: json['notes'] as String? ?? '',
      workConfirmationRequired:
          json['workConfirmationRequired'] as bool? ?? false,
      workConfirmationStatus: WorkConfirmationStatus.values.firstWhere(
        (status) => status.name == json['workConfirmationStatus'],
        orElse: () => WorkConfirmationStatus.pending,
      ),
      workConfirmationSource: json['workConfirmationSource'] as String?,
      workConfirmationReason: json['workConfirmationReason'] as String?,
      workConfirmedAt:
          DateTime.tryParse(json['workConfirmedAt'] as String? ?? ''),
      workConfirmedByMemberId: json['workConfirmedByMemberId'] as String?,
    );
  }
}

enum ShiftStatus { confirmed, available, changed }

enum WorkConfirmationStatus { pending, confirmed, absent }
