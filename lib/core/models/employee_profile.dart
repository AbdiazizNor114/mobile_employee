class EmployeeProfile {
  const EmployeeProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isCareAssistant,
    required this.isTeamLead,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final bool isCareAssistant;
  final bool isTeamLead;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isEmpty ? '' : firstName[0];
    final last = lastName.isEmpty ? '' : lastName[0];
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? 'SN' : value;
  }

  String get primaryRole {
    if (isCareAssistant) return 'Care assistant';
    if (isTeamLead) return 'Team lead';
    return 'Employee';
  }

  EmployeeProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    bool? isCareAssistant,
    bool? isTeamLead,
  }) {
    return EmployeeProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isCareAssistant: isCareAssistant ?? this.isCareAssistant,
      isTeamLead: isTeamLead ?? this.isTeamLead,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isCareAssistant': isCareAssistant,
      'isTeamLead': isTeamLead,
    };
  }

  factory EmployeeProfile.fromJson(Map<dynamic, dynamic> json) {
    return EmployeeProfile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      isCareAssistant: json['isCareAssistant'] as bool? ?? false,
      isTeamLead: json['isTeamLead'] as bool? ?? false,
    );
  }
}
