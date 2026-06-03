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
  });

  final String id;
  final String role;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final ShiftStatus status;
  final String notes;

  Shift copyWith({
    String? id,
    String? role,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    int? breakMinutes,
    ShiftStatus? status,
    String? notes,
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
    };
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
    );
  }
}

enum ShiftStatus { confirmed, available, changed }
