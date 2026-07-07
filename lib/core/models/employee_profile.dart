class EmployeeProfile {
  const EmployeeProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isCareAssistant,
    required this.isTeamLead,
    this.jobTitle = '',
    this.companyRole = '',
    this.profilePhotoUrl = '',
    this.preferredLanguage = 'en',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final bool isCareAssistant;
  final bool isTeamLead;
  final String jobTitle;
  final String companyRole;
  final String profilePhotoUrl;
  final String preferredLanguage;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isEmpty ? '' : firstName[0];
    final last = lastName.isEmpty ? '' : lastName[0];
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? 'SN' : value;
  }

  String get primaryRole {
    if (jobTitle.trim().isNotEmpty) return jobTitle.trim();
    if (isCareAssistant) return 'Care assistant';
    if (isTeamLead) return 'Team lead';
    return 'Employee';
  }

  String get companyRoleLabel {
    final value = companyRole.trim();
    if (value.isEmpty) return 'Employee';
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  EmployeeProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    bool? isCareAssistant,
    bool? isTeamLead,
    String? jobTitle,
    String? companyRole,
    String? profilePhotoUrl,
    String? preferredLanguage,
  }) {
    return EmployeeProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isCareAssistant: isCareAssistant ?? this.isCareAssistant,
      isTeamLead: isTeamLead ?? this.isTeamLead,
      jobTitle: jobTitle ?? this.jobTitle,
      companyRole: companyRole ?? this.companyRole,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
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
      'jobTitle': jobTitle,
      'companyRole': companyRole,
      'profilePhotoUrl': profilePhotoUrl,
      'preferredLanguage': preferredLanguage,
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
      jobTitle: json['jobTitle'] as String? ?? '',
      companyRole: json['companyRole'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? '',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }
}

class StaffContact {
  const StaffContact({
    required this.id,
    required this.name,
    required this.role,
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.profilePhotoUrl = '',
  });

  final String id;
  final String name;
  final String role;
  final String jobTitle;
  final String email;
  final String phone;
  final String profilePhotoUrl;

  String get displayName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty && trimmedName != email.trim()) {
      return trimmedName;
    }
    if (email.trim().isNotEmpty) return email.trim();
    return roleLabel;
  }

  String get subtitle {
    final title = jobTitle.trim();
    if (title.isNotEmpty) return title;
    return roleLabel;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final value = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return value.isEmpty ? 'SN' : value;
  }

  String get roleLabel {
    if (role == 'company_admin') return 'Admin';
    if (role == 'manager') return 'Manager';
    return 'Contact';
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'jobTitle': jobTitle,
      'email': email,
      'phone': phone,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  factory StaffContact.fromJson(Map<dynamic, dynamic> json) {
    return StaffContact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? '',
    );
  }
}
