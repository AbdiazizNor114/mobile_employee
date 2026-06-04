import '../models/activity_item.dart';
import '../models/absence_request.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';
import '../models/message.dart';
import '../models/time_entry.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WorkerSyncPayload {
  const WorkerSyncPayload({
    required this.profile,
    required this.companyPlan,
    required this.shifts,
    required this.activities,
    required this.messages,
    required this.absenceRequests,
    required this.timeEntries,
  });

  final EmployeeProfile profile;
  final String companyPlan;
  final List<Shift> shifts;
  final List<ActivityItem> activities;
  final List<AppMessage> messages;
  final List<AbsenceRequest> absenceRequests;
  final List<TimeEntry> timeEntries;
}

class WorkerSyncService {
  WorkerSyncService({
    required ApiService apiService,
    required AuthService authService,
  })  : _apiService = apiService,
        _authService = authService;

  final ApiService _apiService;
  final AuthService _authService;

  Future<WorkerSyncPayload> fetchWorkerData() async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    final meResponse =
        await _apiService.client.get<Map<String, dynamic>>('/api/v1/me');
    final meData = (meResponse.data?['data'] as Map?) ?? const {};
    final profileMap = (meData['profile'] as Map?) ?? const {};
    final List memberships = (meData['memberships'] as List?) ?? const [];

    String companyPlan = 'free';
    try {
      final companyResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId',
      );
      final companyData = (companyResponse.data?['data'] as Map?) ?? const {};
      final company = (companyData['company'] as Map?) ?? const {};
      companyPlan = ((company['plan'] as String?) ?? 'free').toLowerCase();
    } catch (_) {}

    Map employeeData = const {};
    try {
      final employeeResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/employees/$membershipId',
      );
      employeeData = (employeeResponse.data?['data'] as Map?) ?? const {};
    } catch (_) {}

    final shiftsResponse = await _apiService.client.get<Map<String, dynamic>>(
      '/api/v1/companies/$companyId/shifts',
    );
    final shiftsRaw = (shiftsResponse.data?['data'] as List?) ?? const [];

    List activityRaw = const [];
    try {
      final activityResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/activity',
      );
      activityRaw = (activityResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    List messagesRaw = const [];
    try {
      final messagesResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/messages',
      );
      messagesRaw = (messagesResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    List absenceRaw = const [];
    try {
      final absenceResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/absences',
      );
      absenceRaw = (absenceResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    List timeEntryRaw = const [];
    try {
      final timeEntryResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/time-entries',
      );
      timeEntryRaw = (timeEntryResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    return WorkerSyncPayload(
      profile: _mapProfile(profileMap, memberships, employeeData, shiftsRaw),
      companyPlan: companyPlan,
      shifts: shiftsRaw
          .whereType<Map>()
          .map((raw) => _mapShift(raw, membershipId))
          .whereType<Shift>()
          .toList(),
      activities: activityRaw.whereType<Map>().map(_mapActivity).toList(),
      messages: messagesRaw.whereType<Map>().map(_mapMessage).toList(),
      absenceRequests:
          absenceRaw.whereType<Map>().map(_mapAbsenceRequest).toList(),
      timeEntries: timeEntryRaw.whereType<Map>().map(_mapTimeEntry).toList(),
    );
  }

  Future<void> acceptShift(String shiftId) async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    await _apiService.client.post(
      '/api/v1/companies/$companyId/shifts/$shiftId/accept',
      data: {'membership_id': membershipId},
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    await _apiService.client.patch(
      '/api/v1/companies/$companyId/messages/$messageId/read',
    );
  }

  Future<void> sendMessageToManagers(String content) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    await _apiService.client.post(
      '/api/v1/companies/$companyId/messages',
      data: {
        'subject': 'Worker message',
        'content': content,
        'recipientRole': 'manager',
      },
    );
  }

  Future<void> updateProfile(EmployeeProfile profile) async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    await _apiService.client.patch(
      '/api/v1/companies/$companyId/employees/$membershipId',
      data: {
        'first_name': profile.firstName,
        'last_name': profile.lastName,
        'email': profile.email,
        'phone': profile.phoneNumber,
        'job_title': profile.jobTitle,
        'profile_photo_url': profile.profilePhotoUrl,
      },
    );
  }

  Future<AbsenceRequest> submitAbsenceRequest({
    required AbsenceType type,
    required DateTime startDate,
    required DateTime endDate,
    String note = '',
  }) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    final response = await _apiService.client.post<Map<String, dynamic>>(
      '/api/v1/companies/$companyId/absences',
      data: {
        'type': type.name,
        'startDate': _dateOnly(startDate),
        'endDate': _dateOnly(endDate),
        'notes': note,
      },
    );
    final raw = (response.data?['data'] as Map?)?['absence'] as Map?;
    if (raw == null) {
      throw StateError('Missing absence response.');
    }
    return _mapAbsenceRequest(raw);
  }

  Future<TimeEntry> clockIn({String? shiftId}) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    final response = await _apiService.client.post<Map<String, dynamic>>(
      '/api/v1/companies/$companyId/time-entries/clock-in',
      data: {
        if (shiftId != null && shiftId.trim().isNotEmpty) 'shiftId': shiftId,
      },
    );
    final raw = (response.data?['data'] as Map?)?['entry'] as Map?;
    if (raw == null) throw StateError('Missing time entry response.');
    return _mapTimeEntry(raw);
  }

  Future<TimeEntry> clockOut({
    required String entryId,
    int breakMinutes = 0,
    String notes = '',
  }) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    final response = await _apiService.client.patch<Map<String, dynamic>>(
      '/api/v1/companies/$companyId/time-entries/$entryId/clock-out',
      data: {
        'breakMinutes': breakMinutes,
        'notes': notes,
      },
    );
    final raw = (response.data?['data'] as Map?)?['entry'] as Map?;
    if (raw == null) throw StateError('Missing time entry response.');
    return _mapTimeEntry(raw);
  }

  EmployeeProfile _mapProfile(
    Map profile,
    List memberships,
    Map employee,
    List shiftsRaw,
  ) {
    final firstName =
        (employee['first_name'] ?? profile['first_name'] ?? '') as String;
    final lastName =
        (employee['last_name'] ?? profile['last_name'] ?? '') as String;
    final role = (employee['role'] as String?) ??
        (memberships.isNotEmpty && memberships.first is Map
            ? ((memberships.first as Map)['role'] as String?) ?? ''
            : '');
    final employeeJobTitle = (employee['job_title'] as String?) ?? '';
    final companyMembership = memberships.whereType<Map>().firstWhere(
          (m) => '${m['company_id']}' == _authService.companyId,
          orElse: () => const {},
        );
    final membershipPhoto =
        (companyMembership['profile_photo_url'] as String?) ?? '';
    final membershipJobTitle =
        (companyMembership['job_title'] as String?) ?? '';
    return EmployeeProfile(
      firstName: firstName,
      lastName: lastName,
      email: (employee['email'] ?? profile['email'] ?? '') as String,
      phoneNumber: (employee['phone'] ?? profile['phone'] ?? '') as String,
      isCareAssistant: role == 'worker',
      isTeamLead: role == 'manager',
      jobTitle: employeeJobTitle.trim().isNotEmpty
          ? employeeJobTitle
          : membershipJobTitle,
      companyRole: role,
      profilePhotoUrl: membershipPhoto,
    );
  }

  Shift? _mapShift(Map raw, String membershipId) {
    if (raw['deleted_at'] != null) {
      return null;
    }

    final date = (raw['shift_date'] as String?) ?? '';
    final startTime = (raw['start_time'] as String?) ?? '00:00:00';
    final endTime = (raw['end_time'] as String?) ?? '00:00:00';
    final start = DateTime.tryParse('${date}T$startTime');
    final parsedEnd = DateTime.tryParse('${date}T$endTime');
    if (start == null || parsedEnd == null) {
      return null;
    }
    var end = parsedEnd;
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final assignedMembershipId = (raw['assigned_member_id'] as String?) ?? '';
    final status = (raw['status'] as String?) ?? '';
    final isAssignedStatus = status == 'assigned' ||
        status == 'published' ||
        status == 'confirmed' ||
        status == 'accepted' ||
        status == 'completed';
    if (assignedMembershipId.isNotEmpty &&
        isAssignedStatus &&
        assignedMembershipId != membershipId) {
      return null;
    }
    if (!isAssignedStatus && status != 'open') {
      return null;
    }
    final breakMinutesRaw = raw['break_minutes'];
    final breakMinutes = breakMinutesRaw is int
        ? breakMinutesRaw
        : int.tryParse('$breakMinutesRaw') ?? 0;

    return Shift(
      id: (raw['id'] as String?) ?? '',
      role: (raw['job_role'] as String?) ?? 'Shift',
      location: ((raw['location'] as String?) ?? '').isEmpty
          ? 'ShaqoNet'
          : (raw['location'] as String),
      startsAt: start,
      endsAt: end,
      breakMinutes: breakMinutes,
      status: switch (status) {
        'open' => ShiftStatus.available,
        'assigned' ||
        'published' ||
        'confirmed' ||
        'accepted' ||
        'completed' =>
          ShiftStatus.confirmed,
        _ => ShiftStatus.changed,
      },
      notes: (raw['notes'] as String?)?.trim() ?? '',
    );
  }

  AbsenceRequest _mapAbsenceRequest(Map raw) {
    return AbsenceRequest(
      id: (raw['id'] as String?) ?? '',
      type: AbsenceType.values.firstWhere(
        (type) => type.name == raw['type'],
        orElse: () => AbsenceType.vacation,
      ),
      startDate: DateTime.tryParse((raw['start_date'] as String?) ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse((raw['end_date'] as String?) ?? '') ??
          DateTime.now(),
      status: AbsenceStatus.values.firstWhere(
        (status) => status.name == raw['status'],
        orElse: () => AbsenceStatus.pending,
      ),
      createdAt: DateTime.tryParse((raw['created_at'] as String?) ?? '') ??
          DateTime.now(),
      note: (raw['notes'] as String?) ?? '',
      managerNote: (raw['manager_note'] as String?) ?? '',
      reviewedAt: DateTime.tryParse((raw['reviewed_at'] as String?) ?? ''),
    );
  }

  TimeEntry _mapTimeEntry(Map raw) {
    return TimeEntry(
      id: (raw['id'] as String?) ?? '',
      shiftId: raw['shift_id'] as String?,
      clockInAt: DateTime.tryParse((raw['clock_in_at'] as String?) ?? '') ??
          DateTime.now(),
      clockOutAt: DateTime.tryParse((raw['clock_out_at'] as String?) ?? ''),
      breakMinutes: raw['break_minutes'] as int? ?? 0,
      workedMinutes: raw['worked_minutes'] as int? ?? 0,
      notes: (raw['notes'] as String?) ?? '',
      status: TimeEntryStatus.values.firstWhere(
        (status) => status.name == raw['status'],
        orElse: () => TimeEntryStatus.open,
      ),
    );
  }

  ActivityItem _mapActivity(Map raw) {
    final createdAt = DateTime.tryParse((raw['createdAt'] as String?) ?? '') ??
        DateTime.now();
    final typeRaw = (raw['type'] as String?) ?? '';
    return ActivityItem(
      id: (raw['id'] as String?) ??
          'activity-${createdAt.millisecondsSinceEpoch}',
      title: _toTitle(typeRaw),
      detail: (raw['description'] as String?) ?? 'Activity update',
      createdAt: createdAt,
      type:
          typeRaw.contains('shift') ? ActivityType.shift : ActivityType.system,
      isUnread: false,
    );
  }

  AppMessage _mapMessage(Map raw) {
    return AppMessage.fromJson(raw);
  }

  String _toTitle(String value) {
    if (value.isEmpty) return 'Update';
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
